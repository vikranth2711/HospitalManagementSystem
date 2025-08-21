"""
Document Processing Service for handling patient document uploads and OCR processing
"""
import os
import logging
from typing import List, Dict, Optional
from django.core.files.storage import default_storage
from django.conf import settings
from .models import Patient, PatientHistory, PatientHistoryDocs
from .ocr_service import GeminiOCRService

logger = logging.getLogger(__name__)

class DocumentProcessingService:
    """
    Service for handling sequential document processing with OCR
    """
    
    def __init__(self):
        self.ocr_service = GeminiOCRService()
    
    def upload_documents(self, patient_id: int, files: List, document_types: List[str] = None) -> Dict:
        """
        Upload multiple documents for a patient and store in PatientHistoryDocs
        
        Args:
            patient_id: ID of the patient
            files: List of uploaded files
            document_types: Optional list of document types (same length as files)
        
        Returns:
            Dict with upload status and document IDs
        """
        try:
            # Validate patient exists
            patient = Patient.objects.get(patient_id=patient_id)
            
            uploaded_docs = []
            errors = []
            
            for i, file in enumerate(files):
                try:
                    # Determine document type
                    doc_type = 'other'  # default
                    if document_types and i < len(document_types):
                        doc_type = document_types[i]
                    
                    # Save file to storage
                    file_path = self._save_uploaded_file(file, patient_id)
                    
                    # Create document record
                    doc = PatientHistoryDocs.objects.create(
                        patient=patient,
                        document_type=doc_type,
                        document_name=file.name,
                        document_url=file_path,
                        document_processed=False
                    )
                    
                    uploaded_docs.append({
                        'doc_id': doc.doc_id,
                        'document_name': doc.document_name,
                        'document_type': doc.document_type,
                        'file_path': file_path
                    })
                    
                    logger.info(f"Uploaded document {file.name} for patient {patient_id}")
                    
                except Exception as e:
                    error_msg = f"Failed to upload {file.name}: {str(e)}"
                    errors.append(error_msg)
                    logger.error(error_msg)
            
            return {
                'success': True,
                'uploaded_documents': uploaded_docs,
                'errors': errors,
                'total_uploaded': len(uploaded_docs)
            }
            
        except Patient.DoesNotExist:
            return {
                'success': False,
                'error': f'Patient with ID {patient_id} not found'
            }
        except Exception as e:
            logger.error(f"Error uploading documents for patient {patient_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def process_patient_documents(self, patient_id: int) -> Dict:
        """
        Process all unprocessed documents for a patient sequentially
        
        Args:
            patient_id: ID of the patient
        
        Returns:
            Dict with processing results
        """
        try:
            patient = Patient.objects.get(patient_id=patient_id)
            
            # Get all unprocessed documents
            unprocessed_docs = PatientHistoryDocs.objects.filter(
                patient=patient,
                document_processed=False
            ).order_by('created_at')
            
            if not unprocessed_docs.exists():
                return {
                    'success': True,
                    'message': 'No unprocessed documents found',
                    'processed_count': 0,
                    'failed_count': 0,
                    'total_documents': 0,
                    'errors': []
                }
            
            # Get or create patient history record
            patient_history, created = PatientHistory.objects.get_or_create(
                patient=patient,
                defaults={
                    'history': {},
                    'allergies': [],
                    'notes': []
                }
            )
            
            processed_count = 0
            processing_errors = []
            
            # Process each document sequentially
            for doc in unprocessed_docs:
                try:
                    result = self._process_single_document(doc, patient_history)
                    if result['success']:
                        processed_count += 1
                        logger.info(f"Successfully processed document {doc.doc_id}")
                    else:
                        processing_errors.append(f"Doc {doc.doc_id}: {result['error']}")
                        
                except Exception as e:
                    error_msg = f"Failed to process document {doc.doc_id}: {str(e)}"
                    processing_errors.append(error_msg)
                    logger.error(error_msg)
                    
                    # Mark as processed with error remarks
                    doc.document_processed = True
                    doc.document_remarks = f"Processing failed: {str(e)}"
                    doc.save()
            
            return {
                'success': True,
                'processed_count': processed_count,
                'failed_count': len(processing_errors),
                'total_documents': unprocessed_docs.count(),
                'errors': processing_errors,
                'patient_history_updated': True
            }
            
        except Patient.DoesNotExist:
            return {
                'success': False,
                'error': f'Patient with ID {patient_id} not found'
            }
        except Exception as e:
            logger.error(f"Error processing documents for patient {patient_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def _process_single_document(self, doc: PatientHistoryDocs, patient_history: PatientHistory) -> Dict:
        """
        Process a single document with OCR and update patient history
        
        Args:
            doc: PatientHistoryDocs instance
            patient_history: PatientHistory instance to update
        
        Returns:
            Dict with processing result
        """
        try:
            # Get absolute file path
            file_path = self._get_absolute_file_path(doc.document_url)
            
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"Document file not found: {file_path}")
            
            # Process with OCR
            ocr_result = self.ocr_service.process_document(
                file_path, 
                document_type_hint=doc.document_type
            )
            
            # Check if OCR was successful
            if ocr_result.get('error'):
                doc.document_processed = True
                doc.document_remarks = ocr_result.get('processing_notes', 'OCR processing failed')
                doc.save()
                return {
                    'success': False,
                    'error': ocr_result.get('processing_notes', 'OCR processing failed')
                }
            
            # Update document type if OCR detected a different type
            detected_type = ocr_result.get('document_type', doc.document_type)
            if detected_type != doc.document_type:
                logger.info(f"Document type updated from {doc.document_type} to {detected_type}")
                doc.document_type = detected_type
            
            # Merge extracted data with existing patient history
            updated_history = self.ocr_service.merge_patient_history(
                patient_history.history, 
                ocr_result
            )
            
            updated_allergies = self.ocr_service.merge_patient_allergies(
                patient_history.allergies,
                ocr_result
            )
            
            updated_notes = self.ocr_service.merge_patient_notes(
                patient_history.notes,
                ocr_result
            )
            
            # Update patient history
            patient_history.history = updated_history
            patient_history.allergies = updated_allergies
            patient_history.notes = updated_notes
            patient_history.save()
            
            # Mark document as processed
            doc.document_processed = True
            doc.document_remarks = f"Successfully processed. Confidence: {ocr_result.get('confidence', 'unknown')}"
            doc.save()
            
            logger.info(f"Successfully processed document {doc.doc_id} for patient {doc.patient.patient_id}")
            
            return {
                'success': True,
                'ocr_result': ocr_result,
                'confidence': ocr_result.get('confidence', 'unknown')
            }
            
        except Exception as e:
            logger.error(f"Error processing document {doc.doc_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_patient_consolidated_history(self, patient_id: int) -> Dict:
        """
        Get consolidated medical history for a patient
        
        Args:
            patient_id: ID of the patient
        
        Returns:
            Dict with consolidated history and related documents
        """
        try:
            patient = Patient.objects.get(patient_id=patient_id)
            
            # Get patient history
            try:
                patient_history = PatientHistory.objects.get(patient=patient)
                history_data = {
                    'history': patient_history.history,
                    'allergies': patient_history.allergies,
                    'notes': patient_history.notes,
                    'last_updated': patient_history.updated_at.isoformat()
                }
            except PatientHistory.DoesNotExist:
                history_data = {
                    'history': {},
                    'allergies': [],
                    'notes': [],
                    'last_updated': None
                }
            
            # Get all related documents
            documents = PatientHistoryDocs.objects.filter(patient=patient).order_by('-created_at')
            doc_data = []
            
            for doc in documents:
                doc_data.append({
                    'doc_id': doc.doc_id,
                    'document_type': doc.document_type,
                    'document_name': doc.document_name,
                    'document_processed': doc.document_processed,
                    'created_at': doc.created_at.isoformat(),
                    'document_remarks': doc.document_remarks
                })
            
            return {
                'success': True,
                'patient': {
                    'patient_id': patient.patient_id,
                    'patient_name': patient.patient_name,
                    'patient_email': patient.patient_email
                },
                'medical_history': history_data,
                'documents': doc_data,
                'total_documents': len(doc_data),
                'processed_documents': len([d for d in doc_data if d['document_processed']])
            }
            
        except Patient.DoesNotExist:
            return {
                'success': False,
                'error': f'Patient with ID {patient_id} not found'
            }
        except Exception as e:
            logger.error(f"Error getting consolidated history for patient {patient_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def _save_uploaded_file(self, file, patient_id: int) -> str:
        """
        Save uploaded file to storage and return the file path
        """
        # Create directory structure: patient_documents/patient_id/
        upload_path = f"patient_documents/{patient_id}/"
        
        # Generate unique filename to avoid conflicts
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{file.name}"
        
        full_path = f"{upload_path}{filename}"
        
        # Save file
        saved_path = default_storage.save(full_path, file)
        
        return saved_path
    
    def _get_absolute_file_path(self, relative_path: str) -> str:
        """
        Convert relative storage path to absolute file system path
        """
        media_root = getattr(settings, 'MEDIA_ROOT', '')
        return os.path.join(media_root, relative_path)
    
    def get_document_processing_status(self, patient_id: int) -> Dict:
        """
        Get processing status for all documents of a patient
        """
        try:
            patient = Patient.objects.get(patient_id=patient_id)
            
            documents = PatientHistoryDocs.objects.filter(patient=patient)
            total_docs = documents.count()
            processed_docs = documents.filter(document_processed=True).count()
            
            status_data = []
            for doc in documents.order_by('-created_at'):
                status_data.append({
                    'doc_id': doc.doc_id,
                    'document_name': doc.document_name,
                    'document_type': doc.document_type,
                    'processed': doc.document_processed,
                    'created_at': doc.created_at.isoformat(),
                    'remarks': doc.document_remarks
                })
            
            return {
                'success': True,
                'patient_id': patient_id,
                'total_documents': total_docs,
                'processed_documents': processed_docs,
                'pending_documents': total_docs - processed_docs,
                'processing_complete': processed_docs == total_docs,
                'documents': status_data
            }
            
        except Patient.DoesNotExist:
            return {
                'success': False,
                'error': f'Patient with ID {patient_id} not found'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
