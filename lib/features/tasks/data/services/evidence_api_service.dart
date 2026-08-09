import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class EvidenceDto {
  final String evidenceId;
  final String fileUrl;
  final String? description;
  final String createdAt;

  EvidenceDto({
    required this.evidenceId,
    required this.fileUrl,
    this.description,
    required this.createdAt,
  });

  factory EvidenceDto.fromJson(Map<String, dynamic> json) {
    return EvidenceDto(
      evidenceId: json['evidenceId']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class EvidenceApiService {
  final ApiClient _apiClient;

  EvidenceApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<EvidenceDto> upload(File file, {String? description}) async {
    final fileName = file.path.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      if (description != null) 'description': description,
    });

    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/evidence/upload',
      method: 'POST',
      body: formData,
      isFormData: true,
    );
    return EvidenceDto.fromJson(response);
  }

  Future<EvidenceDto> getById(String evidenceId) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/evidence/$evidenceId',
    );
    return EvidenceDto.fromJson(response);
  }
}
