/// KLE HOMECARE — ServiceRequest Data Model
/// All ObjectIds from API are plain strings.
class ServiceRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? contactNumber;
  final String serviceType;
  final String? description;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final String preferredDate;
  final int numDays;
  final String? preferredTime;
  final String urgencyLevel;
  final String status;
  final String? specialNotes;
  final String? assignedNurseId;
  final String? assignedNurseName;
  final String createdAt;
  final String updatedAt;

  const ServiceRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.contactNumber,
    required this.serviceType,
    this.description,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    required this.preferredDate,
    required this.numDays,
    this.preferredTime,
    required this.urgencyLevel,
    required this.status,
    this.specialNotes,
    this.assignedNurseId,
    this.assignedNurseName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id:                 json['id'] as String,
      patientId:          json['patient_id'] as String,
      patientName:        json['patient_name'] as String,
      contactNumber:      json['contact_number'] as String?,
      serviceType:        json['service_type'] as String,
      description:        json['description'] as String?,
      address:            json['address'] as String,
      city:               json['city'] as String,
      state:              json['state'] as String?,
      pincode:            json['pincode'] as String?,
      preferredDate:      json['preferred_date'] as String,
      numDays:            json['num_days'] as int,
      preferredTime:      json['preferred_time'] as String?,
      urgencyLevel:       json['urgency_level'] as String,
      status:             json['status'] as String,
      specialNotes:       json['special_notes'] as String?,
      assignedNurseId:    json['assigned_nurse_id'] as String?,
      assignedNurseName:  json['assigned_nurse_name'] as String?,
      createdAt:          json['created_at'] as String,
      updatedAt:          json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':                   id,
    'patient_id':           patientId,
    'patient_name':         patientName,
    'contact_number':       contactNumber,
    'service_type':         serviceType,
    'description':          description,
    'address':              address,
    'city':                 city,
    'state':                state,
    'pincode':              pincode,
    'preferred_date':       preferredDate,
    'num_days':             numDays,
    'preferred_time':       preferredTime,
    'urgency_level':        urgencyLevel,
    'status':               status,
    'special_notes':        specialNotes,
    'assigned_nurse_id':    assignedNurseId,
    'assigned_nurse_name':  assignedNurseName,
    'created_at':           createdAt,
    'updated_at':           updatedAt,
  };
}
