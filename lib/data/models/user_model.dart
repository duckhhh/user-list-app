import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String image;
  final String phone;
  final String username;
  final Map<String, dynamic> address;
  final String company;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.image,
    required this.phone,
    required this.username,
    required this.address,
    required this.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] is int)
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      address: (json['address'] is Map) ? json['address'] : {},
      company: (json['company'] is Map && json['company']['name'] != null)
          ? json['company']['name'].toString()
          : json['company']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'image': image,
      'phone': phone,
      'username': username,
      'address': address,
      'company': company,
    };
  }

  String get fullName => '$firstName $lastName';

  @override
  List<Object> get props => [id, firstName, lastName, email, image, phone, username];
}
