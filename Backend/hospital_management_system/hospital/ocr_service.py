"""
OCR Service for processing patient documents using Gemini-2.5-Pro
"""
import os
import base64
import json
import logging
import mimetypes
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage

import google.genai as genai
from PIL import Image
import PyPDF2
import io
from .models import PatientHistoryDocs

logger = logging.getLogger(__name__)

class GeminiOCRService:
    """
    Service class for processing patient documents using Gemini-2.5-Pro OCR
    """
    
    def __init__(self):
        """Initialize Gemini API configuration"""
        try:
            api_key = getattr(settings, 'GEMINI_API_KEY', None)
            if not api_key:
                raise ValueError("GEMINI_API_KEY not found in Django settings")
            
            # Initialize Gemini client with new API
            self.client = genai.Client(api_key=api_key)
            logger.info("Gemini OCR Service initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Gemini OCR Service: {str(e)}")
            raise
    
    def get_document_type_choices(self) -> List[Tuple[str, str]]:
        """
        Get available document type choices
        """
        from .models import PatientHistoryDocs
        return PatientHistoryDocs.DOCUMENT_TYPE_CHOICES
    
    def get_supported_formats(self) -> Dict[str, List[str]]:
        """
        Get list of all supported file formats
        """
        return {
            "image_formats": [
                ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif",
                ".webp", ".svg", ".ico", ".psd", ".raw", ".heic", ".heif"
            ],
            "document_formats": [
                ".pdf"
            ],
            "text_formats": [
                ".txt", ".doc", ".docx", ".odt", ".rtf"
            ],
            "mime_types": [
                "image/*", "application/pdf", "text/plain",
                "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            ]
        }
    
    def is_supported_format(self, file_path: str) -> bool:
        """
        Check if file format is supported
        """
        try:
            self.detect_file_type(file_path)
            return True
        except ValueError:
            return False
        """
        Get document type choices from the model to provide context to LLM
        """
        choices = PatientHistoryDocs.DOCUMENT_TYPE_CHOICES
        return ", ".join([f"{code}: {label}" for code, label in choices])
    
    def detect_file_type(self, file_path: str) -> Tuple[str, str]:
        """
        Detect file type using multiple methods for better accuracy
        Returns: (file_type, mime_type)
        """
        try:
            # Get file extension
            file_extension = os.path.splitext(file_path)[1].lower()
            
            # Get MIME type
            mime_type, _ = mimetypes.guess_type(file_path)
            
            # Comprehensive image format support
            image_extensions = {
                '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.tif', 
                '.webp', '.svg', '.ico', '.psd', '.raw', '.heic', '.heif'
            }
            
            # PDF extensions
            pdf_extensions = {'.pdf'}
            
            # Additional document formats that might contain images
            document_extensions = {'.doc', '.docx', '.odt', '.rtf'}
            
            if file_extension in image_extensions:
                return 'image', mime_type or 'image/jpeg'
            elif file_extension in pdf_extensions:
                return 'pdf', mime_type or 'application/pdf'
            elif file_extension in document_extensions:
                return 'document', mime_type or 'application/octet-stream'
            else:
                # Try to detect by MIME type if extension is unknown
                if mime_type:
                    if mime_type.startswith('image/'):
                        return 'image', mime_type
                    elif mime_type == 'application/pdf':
                        return 'pdf', mime_type
                    elif mime_type.startswith('application/') and any(doc in mime_type for doc in ['word', 'document']):
                        return 'document', mime_type
                
                # Fallback: try to open as image
                try:
                    with Image.open(file_path) as img:
                        return 'image', f'image/{img.format.lower()}'
                except Exception:
                    pass
                
                raise ValueError(f"Unsupported file format: {file_extension} (MIME: {mime_type})")
                
        except Exception as e:
            logger.error(f"Error detecting file type for {file_path}: {str(e)}")
            raise
    
    def create_ocr_prompt(self, document_type_hint: Optional[str] = None) -> str:
        """
        Create a comprehensive prompt for Gemini to extract medical information
        """
        document_types = self.get_document_type_choices()
        
        prompt = f"""
You are a medical document processing AI. Extract information from this medical document and return it in valid JSON format.

DOCUMENT TYPES AVAILABLE: {document_types}

INSTRUCTIONS:
1. First, identify the document type from the available choices: {document_types}
2. Extract structured medical information based on the document type
3. Return ONLY valid JSON in this exact format:

{{
    "document_type": "one of: lab_report, prescription, discharge_summary, other",
    "confidence": "high/medium/low",
    "extracted_data": {{
        "history": {{
            "diseases": ["list of diseases/conditions mentioned"],
            "surgeries": ["list of surgeries/procedures"],
            "medications": ["list of current/past medications"],
            "chronic_conditions": ["list of chronic conditions"],
            "family_history": ["relevant family medical history"]
        }},
        "allergies": ["list of allergies mentioned"],
        "notes": [
            "any doctor notes or observations",
            "treatment recommendations",
            "follow-up instructions",
            "other unstructured medical text"
        ],
        "vital_signs": {{
            "blood_pressure": "if mentioned",
            "heart_rate": "if mentioned", 
            "temperature": "if mentioned",
            "other_vitals": "any other vital signs"
        }},
        "lab_results": {{
            "test_name": "result_value and unit",
            "normal_ranges": "if provided"
        }},
        "prescriptions": [
            {{
                "medication_name": "name",
                "dosage": "dosage instructions",
                "frequency": "how often",
                "duration": "how long"
            }}
        ]
    }},
    "processing_notes": "any issues with OCR or unclear text"
}}

IMPORTANT RULES:
- Return ONLY the JSON response, no other text
- If information is not available, use empty arrays [] or empty strings ""
- Be specific and accurate - do not hallucinate information
- If text is unclear, mention it in processing_notes
- Focus on medically relevant information only
"""
        
        if document_type_hint:
            prompt += f"\n\nDOCUMENT TYPE HINT: This appears to be a {document_type_hint}"
        
        return prompt
    
    def process_image_document(self, image_path: str, document_type_hint: Optional[str] = None) -> Dict:
        """
        Process image documents with comprehensive format support
        """
        try:
            # Validate and convert image if necessary
            processed_image_path = self._prepare_image_for_processing(image_path)
            
            # Create prompt
            prompt = self.create_ocr_prompt(document_type_hint)
            
            # Upload file to Gemini and process
            uploaded_file = self.client.files.upload(file=processed_image_path)
            
            # Process with Gemini
            response = self.client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[uploaded_file, prompt]
            )
            
            # Clean up temporary file if created
            if processed_image_path != image_path and os.path.exists(processed_image_path):
                os.remove(processed_image_path)
            
            # Parse JSON response
            result = self._parse_gemini_response(response.text)
            return result
            
        except Exception as e:
            logger.error(f"Error processing image document {image_path}: {str(e)}")
            return self._create_error_response(str(e))
    
    def _prepare_image_for_processing(self, image_path: str) -> str:
        """
        Prepare image for processing - convert to supported format if needed
        """
        try:
            with Image.open(image_path) as img:
                # Convert to RGB if needed (for RGBA, P mode images)
                if img.mode in ('RGBA', 'P'):
                    img = img.convert('RGB')
                
                # Check if image is too large and resize if necessary
                max_size = (4096, 4096)  # Gemini's max resolution
                if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
                    img.thumbnail(max_size, Image.Resampling.LANCZOS)
                    logger.info(f"Resized image from original size to {img.size}")
                
                # Save as JPEG if format is not supported or if we made changes
                original_format = img.format
                supported_formats = {'JPEG', 'PNG', 'GIF', 'BMP', 'TIFF'}
                
                if original_format not in supported_formats or img.mode != Image.open(image_path).mode:
                    # Create temporary file with supported format
                    temp_path = image_path + '_processed.jpg'
                    img.save(temp_path, 'JPEG', quality=95)
                    logger.info(f"Converted {original_format} to JPEG for processing")
                    return temp_path
                
                return image_path
                
        except Exception as e:
            logger.warning(f"Could not prepare image {image_path}: {str(e)}")
            return image_path  # Return original path as fallback
    
    def process_pdf_document(self, pdf_path: str, document_type_hint: Optional[str] = None) -> Dict:
        """
        Process a PDF document by extracting text and using Gemini
        Enhanced to handle both text-based and image-based PDFs
        """
        try:
            # First, try to extract text from PDF
            text_content = self._extract_text_from_pdf(pdf_path)
            
            # If no text extracted, try to process as images
            if not text_content.strip():
                logger.info(f"No text found in PDF {pdf_path}, trying image-based processing")
                return self._process_pdf_as_images(pdf_path, document_type_hint)
            
            # Create prompt with extracted text
            prompt = self.create_ocr_prompt(document_type_hint)
            full_prompt = f"{prompt}\n\nDOCUMENT TEXT:\n{text_content}"
            
            # Process with Gemini
            response = self.client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[full_prompt]
            )
            
            # Parse JSON response
            result = self._parse_gemini_response(response.text)
            return result
            
        except Exception as e:
            logger.error(f"Error processing PDF document {pdf_path}: {str(e)}")
            return self._create_error_response(str(e))
    
    def _extract_text_from_pdf(self, pdf_path: str) -> str:
        """
        Extract text from PDF using PyPDF2 with enhanced error handling
        """
        text_content = ""
        try:
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                
                # Check if PDF is encrypted
                if pdf_reader.is_encrypted:
                    logger.warning(f"PDF {pdf_path} is encrypted, attempting to decrypt")
                    try:
                        pdf_reader.decrypt("")  # Try empty password
                    except Exception:
                        raise ValueError("PDF is password protected and cannot be processed")
                
                # Extract text from all pages
                for page_num, page in enumerate(pdf_reader.pages):
                    try:
                        page_text = page.extract_text()
                        if page_text:
                            text_content += f"\n--- Page {page_num + 1} ---\n{page_text}\n"
                    except Exception as e:
                        logger.warning(f"Could not extract text from page {page_num + 1}: {str(e)}")
                        continue
                
        except Exception as e:
            logger.error(f"Error extracting text from PDF {pdf_path}: {str(e)}")
            raise
        
        return text_content.strip()
    
    def _process_pdf_as_images(self, pdf_path: str, document_type_hint: Optional[str] = None) -> Dict:
        """
        Process PDF by converting pages to images when text extraction fails
        This handles scanned PDFs or image-based PDFs
        """
        try:
            # Try to import pdf2image for converting PDF to images
            try:
                from pdf2image import convert_from_path
            except ImportError:
                logger.error("pdf2image not installed. Cannot process image-based PDFs.")
                return self._create_error_response(
                    "PDF contains no extractable text and pdf2image not available for image processing"
                )
            
            # Convert PDF pages to images
            images = convert_from_path(pdf_path, dpi=300)  # High DPI for better OCR
            
            if not images:
                raise ValueError("Could not convert PDF pages to images")
            
            # Process first few pages (limit to avoid token limits)
            max_pages = 5
            processed_pages = []
            
            for i, image in enumerate(images[:max_pages]):
                try:
                    # Save image temporarily
                    temp_image_path = f"{pdf_path}_page_{i+1}.jpg"
                    image.save(temp_image_path, 'JPEG')
                    
                    # Process the image
                    result = self.process_image_document(temp_image_path, document_type_hint)
                    processed_pages.append(result)
                    
                    # Clean up temporary file
                    os.remove(temp_image_path)
                    
                except Exception as e:
                    logger.warning(f"Error processing page {i+1} of PDF: {str(e)}")
                    continue
            
            if not processed_pages:
                raise ValueError("Could not process any pages from PDF")
            
            # Merge results from all pages
            return self._merge_pdf_page_results(processed_pages)
            
        except Exception as e:
            logger.error(f"Error processing PDF as images {pdf_path}: {str(e)}")
            return self._create_error_response(str(e))
    
    def _merge_pdf_page_results(self, page_results: List[Dict]) -> Dict:
        """
        Merge OCR results from multiple PDF pages
        """
        if not page_results:
            return self._create_error_response("No pages processed successfully")
        
        # Start with the first page result
        merged_result = page_results[0].copy()
        
        if len(page_results) == 1:
            return merged_result
        
        try:
            # Merge extracted data from all pages
            merged_data = merged_result.get('extracted_data', {})
            
            for page_result in page_results[1:]:
                page_data = page_result.get('extracted_data', {})
                
                # Merge lists (history, allergies, notes, etc.)
                for key in ['allergies', 'notes']:
                    if key in page_data and isinstance(page_data[key], list):
                        merged_data.setdefault(key, []).extend(page_data[key])
                
                # Merge history object
                if 'history' in page_data:
                    merged_history = merged_data.setdefault('history', {})
                    for hist_key, hist_value in page_data['history'].items():
                        if isinstance(hist_value, list):
                            merged_history.setdefault(hist_key, []).extend(hist_value)
                        else:
                            merged_history[hist_key] = hist_value
                
                # Merge prescriptions
                if 'prescriptions' in page_data and isinstance(page_data['prescriptions'], list):
                    merged_data.setdefault('prescriptions', []).extend(page_data['prescriptions'])
                
                # Update vital signs and lab results (latest values)
                for key in ['vital_signs', 'lab_results']:
                    if key in page_data:
                        merged_data[key] = page_data[key]
            
            # Remove duplicates from lists
            for key in ['allergies', 'notes']:
                if key in merged_data and isinstance(merged_data[key], list):
                    merged_data[key] = list(set(merged_data[key]))
            
            # Remove duplicates from history lists
            if 'history' in merged_data:
                for hist_key, hist_value in merged_data['history'].items():
                    if isinstance(hist_value, list):
                        merged_data['history'][hist_key] = list(set(hist_value))
            
            merged_result['extracted_data'] = merged_data
            merged_result['processing_notes'] = f"Merged data from {len(page_results)} pages"
            
            return merged_result
            
        except Exception as e:
            logger.error(f"Error merging PDF page results: {str(e)}")
            return page_results[0]  # Return first page as fallback
    
    def process_document(self, file_path: str, document_type_hint: Optional[str] = None, patient_id: Optional[int] = None) -> Dict:
        """
        Main method to process any supported document type with comprehensive format support
        """
        try:
            # Detect file type using enhanced detection
            file_type, mime_type = self.detect_file_type(file_path)
            
            logger.info(f"Processing {file_type} document: {file_path} (MIME: {mime_type})")
            
            if file_type == 'image':
                return self.process_image_document(file_path, document_type_hint)
            elif file_type == 'pdf':
                return self.process_pdf_document(file_path, document_type_hint)
            elif file_type == 'document':
                # For other document types, try to process as text first
                logger.warning(f"Document format {mime_type} not directly supported, attempting text extraction")
                return self._process_unknown_document(file_path, document_type_hint)
            else:
                raise ValueError(f"Unsupported file type: {file_type} (MIME: {mime_type})")
                
        except Exception as e:
            logger.error(f"Error processing document {file_path}: {str(e)}")
            return self._create_error_response(str(e))
    
    def _process_unknown_document(self, file_path: str, document_type_hint: Optional[str] = None) -> Dict:
        """
        Attempt to process unknown document types
        """
        try:
            # Try to read as text file
            with open(file_path, 'r', encoding='utf-8') as file:
                text_content = file.read()
            
            if text_content.strip():
                prompt = self.create_ocr_prompt(document_type_hint)
                full_prompt = f"{prompt}\n\nDOCUMENT TEXT:\n{text_content}"
                
                response = self.client.models.generate_content(
                    model="gemini-2.0-flash",
                    contents=[full_prompt]
                )
                
                return self._parse_gemini_response(response.text)
            else:
                raise ValueError("Document contains no readable text")
                
        except UnicodeDecodeError:
            # Try different encodings
            for encoding in ['latin-1', 'cp1252', 'iso-8859-1']:
                try:
                    with open(file_path, 'r', encoding=encoding) as file:
                        text_content = file.read()
                    if text_content.strip():
                        prompt = self.create_ocr_prompt(document_type_hint)
                        full_prompt = f"{prompt}\n\nDOCUMENT TEXT:\n{text_content}"
                        
                        response = self.client.models.generate_content(
                            model="gemini-2.0-flash",
                            contents=[full_prompt]
                        )
                        
                        return self._parse_gemini_response(response.text)
                except:
                    continue
            
            return self._create_error_response("Could not decode document text with any supported encoding")
        
        except Exception as e:
            logger.error(f"Error processing unknown document {file_path}: {str(e)}")
            return self._create_error_response(str(e))
    
    def _parse_gemini_response(self, response_text: str) -> Dict:
        """
        Parse and validate Gemini's JSON response
        """
        try:
            # Clean the response text (remove markdown formatting if present)
            cleaned_text = response_text.strip()
            if cleaned_text.startswith('```json'):
                cleaned_text = cleaned_text[7:]
            if cleaned_text.endswith('```'):
                cleaned_text = cleaned_text[:-3]
            cleaned_text = cleaned_text.strip()
            
            # Parse JSON
            result = json.loads(cleaned_text)
            
            # Validate required fields
            required_fields = ['document_type', 'confidence', 'extracted_data']
            for field in required_fields:
                if field not in result:
                    raise ValueError(f"Missing required field: {field}")
            
            # Validate document type
            valid_types = [choice[0] for choice in PatientHistoryDocs.DOCUMENT_TYPE_CHOICES]
            if result['document_type'] not in valid_types:
                logger.warning(f"Invalid document type: {result['document_type']}, defaulting to 'other'")
                result['document_type'] = 'other'
            
            return result
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON response: {str(e)}")
            logger.error(f"Raw response: {response_text}")
            return self._create_error_response(f"Invalid JSON response: {str(e)}")
        except Exception as e:
            logger.error(f"Error parsing Gemini response: {str(e)}")
            return self._create_error_response(str(e))
    
    def _create_error_response(self, error_message: str) -> Dict:
        """
        Create a standardized error response
        """
        return {
            "document_type": "other",
            "confidence": "low",
            "extracted_data": {
                "history": {
                    "diseases": [],
                    "surgeries": [],
                    "medications": [],
                    "chronic_conditions": [],
                    "family_history": []
                },
                "allergies": [],
                "notes": [],
                "vital_signs": {},
                "lab_results": {},
                "prescriptions": []
            },
            "processing_notes": f"OCR processing failed: {error_message}",
            "error": True
        }
    
    def merge_patient_history(self, existing_history: Dict, new_data: Dict) -> Dict:
        """
        Merge new extracted data with existing patient history
        """
        try:
            # Initialize if empty
            if not existing_history:
                existing_history = {
                    "diseases": [],
                    "surgeries": [],
                    "medications": [],
                    "chronic_conditions": [],
                    "family_history": []
                }
            
            new_history = new_data.get('extracted_data', {}).get('history', {})
            
            # Merge each category, avoiding duplicates
            for category in ['diseases', 'surgeries', 'medications', 'chronic_conditions', 'family_history']:
                existing_items = set(existing_history.get(category, []))
                new_items = set(new_history.get(category, []))
                merged_items = list(existing_items.union(new_items))
                existing_history[category] = merged_items
            
            return existing_history
            
        except Exception as e:
            logger.error(f"Error merging patient history: {str(e)}")
            return existing_history or {}
    
    def merge_patient_allergies(self, existing_allergies: List, new_data: Dict) -> List:
        """
        Merge new allergies with existing ones
        """
        try:
            new_allergies = new_data.get('extracted_data', {}).get('allergies', [])
            existing_set = set(existing_allergies or [])
            new_set = set(new_allergies)
            return list(existing_set.union(new_set))
        except Exception as e:
            logger.error(f"Error merging allergies: {str(e)}")
            return existing_allergies or []
    
    def merge_patient_notes(self, existing_notes: List, new_data: Dict) -> List:
        """
        Append new notes to existing ones with timestamp
        """
        try:
            new_notes = new_data.get('extracted_data', {}).get('notes', [])
            all_notes = list(existing_notes or [])
            
            # Add new notes with processing timestamp
            from datetime import datetime
            timestamp = datetime.now().isoformat()
            
            for note in new_notes:
                if note and note.strip():
                    all_notes.append({
                        "note": note,
                        "extracted_at": timestamp,
                        "document_type": new_data.get('document_type', 'unknown')
                    })
            
            return all_notes
        except Exception as e:
            logger.error(f"Error merging notes: {str(e)}")
            return existing_notes or []
