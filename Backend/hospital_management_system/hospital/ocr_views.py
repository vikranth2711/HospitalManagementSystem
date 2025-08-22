"""
OCR Views for Patient Document Processing
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.http import Http404
import logging

from accounts.authentication import JWTAuthentication
from .models import Patient, PatientHistory, PatientHistoryDocs
from .serializers import (
    DocumentUploadSerializer, PatientHistorySerializer, 
    PatientHistoryDocsSerializer, ConsolidatedHistorySerializer,
    DocumentProcessingStatusSerializer
)
from .document_processing_service import DocumentProcessingService
from .permissions import IsAdminStaff

logger = logging.getLogger(__name__)

class DocumentUploadView(APIView):
    """
    API endpoint for uploading patient documents
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request):
        """
        Upload multiple documents for a patient
        
        Expected payload:
        - patient_id: integer
        - files: list of files
        - document_types: optional list of document types
        """
        try:
            serializer = DocumentUploadSerializer(data=request.data)
            
            if not serializer.is_valid():
                return Response({
                    'success': False,
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Extract data
            patient_id = serializer.validated_data['patient_id']
            files = serializer.validated_data['files']
            document_types = serializer.validated_data.get('document_types', [])
            
            # Process upload
            processing_service = DocumentProcessingService()
            result = processing_service.upload_documents(
                patient_id=patient_id,
                files=files,
                document_types=document_types
            )
            
            if result['success']:
                return Response({
                    'success': True,
                    'message': f"Successfully uploaded {result['total_uploaded']} documents",
                    'data': result
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'success': False,
                    'error': result['error']
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            logger.error(f"Error in document upload: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error during document upload'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ProcessDocumentsView(APIView):
    """
    API endpoint for processing uploaded documents with OCR
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def post(self, request, patient_id):
        """
        Process all unprocessed documents for a patient
        """
        try:
            # Validate patient exists
            try:
                patient = Patient.objects.get(patient_id=patient_id)
            except Patient.DoesNotExist:
                return Response({
                    'success': False,
                    'error': f'Patient with ID {patient_id} not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Process documents
            processing_service = DocumentProcessingService()
            result = processing_service.process_patient_documents(patient_id)
            
            if result['success']:
                return Response({
                    'success': True,
                    'message': f"Successfully processed {result['processed_count']} documents",
                    'data': result
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'error': result['error']
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            logger.error(f"Error processing documents for patient {patient_id}: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error during document processing'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PatientHistoryView(APIView):
    """
    API endpoint for retrieving consolidated patient medical history
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, patient_id):
        """
        Get consolidated medical history for a patient
        """
        try:
            # Validate patient exists
            try:
                patient = Patient.objects.get(patient_id=patient_id)
            except Patient.DoesNotExist:
                return Response({
                    'success': False,
                    'error': f'Patient with ID {patient_id} not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Get consolidated history
            processing_service = DocumentProcessingService()
            result = processing_service.get_patient_consolidated_history(patient_id)
            
            if result['success']:
                # Return the result data directly instead of wrapping it in 'data'
                response_data = result.copy()
                response_data.pop('success', None)  # Remove the inner success flag
                return Response({
                    'success': True,
                    **response_data
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'error': result['error']
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            logger.error(f"Error getting patient history for {patient_id}: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error while retrieving patient history'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DocumentStatusView(APIView):
    """
    API endpoint for checking document processing status
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, patient_id):
        """
        Get processing status for all documents of a patient
        """
        try:
            # Validate patient exists
            try:
                patient = Patient.objects.get(patient_id=patient_id)
            except Patient.DoesNotExist:
                return Response({
                    'success': False,
                    'error': f'Patient with ID {patient_id} not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Get status
            processing_service = DocumentProcessingService()
            result = processing_service.get_document_processing_status(patient_id)
            
            if result['success']:
                return Response({
                    'success': True,
                    'data': result
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'error': result['error']
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            logger.error(f"Error getting document status for patient {patient_id}: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error while retrieving document status'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PatientHistoryListView(APIView):
    """
    API endpoint for listing patient history records (admin only)
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated, IsAdminStaff]
    
    def get(self, request):
        """
        Get list of all patients with their history status
        """
        try:
            histories = PatientHistory.objects.select_related('patient').all()
            serializer = PatientHistorySerializer(histories, many=True)
            
            return Response({
                'success': True,
                'data': serializer.data,
                'total_records': histories.count()
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error listing patient histories: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error while retrieving patient histories'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class PatientDocumentsListView(APIView):
    """
    API endpoint for listing all documents for a patient
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request, patient_id):
        """
        Get list of all documents for a patient
        """
        try:
            # Validate patient exists
            try:
                patient = Patient.objects.get(patient_id=patient_id)
            except Patient.DoesNotExist:
                return Response({
                    'success': False,
                    'error': f'Patient with ID {patient_id} not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Get documents
            documents = PatientHistoryDocs.objects.filter(
                patient=patient
            ).order_by('-created_at')
            
            serializer = PatientHistoryDocsSerializer(documents, many=True)
            
            return Response({
                'success': True,
                'data': serializer.data,
                'total_documents': documents.count(),
                'processed_documents': documents.filter(document_processed=True).count()
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error listing documents for patient {patient_id}: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error while retrieving patient documents'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class DocumentTypesView(APIView):
    """
    API endpoint for getting available document types
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """
        Get list of available document types
        """
        try:
            document_types = [
                {'code': code, 'label': label} 
                for code, label in PatientHistoryDocs.DOCUMENT_TYPE_CHOICES
            ]
            
            return Response({
                'success': True,
                'document_types': document_types
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error getting document types: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error while retrieving document types'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class SupportedFormatsView(APIView):
    """
    API endpoint for getting supported file formats
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """
        Get list of all supported file formats for document upload
        """
        try:
            from .ocr_service import GeminiOCRService
            
            ocr_service = GeminiOCRService()
            supported_formats = ocr_service.get_supported_formats()
            
            return Response({
                'success': True,
                'supported_formats': supported_formats,
                'max_file_size_mb': 10,  # Typical limit
                'recommendations': {
                    'images': 'High resolution images (300 DPI) work best for OCR',
                    'pdfs': 'Text-based PDFs are processed faster than scanned PDFs',
                    'formats': 'JPEG and PNG are recommended for images',
                    'quality': 'Ensure documents are clear and readable for best results'
                },
                'processing_info': {
                    'supported_image_formats': 'All major image formats including JPEG, PNG, GIF, BMP, TIFF, WebP, HEIC',
                    'pdf_support': 'Both text-based and scanned PDFs are supported',
                    'ocr_engine': 'Powered by Google Gemini-2.5-Pro for high accuracy'
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error getting supported formats: {str(e)}")
            return Response({
                'success': False,
                'error': 'Internal server error while retrieving supported formats'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
