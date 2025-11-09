import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupModel {
  final int id;
  final String name;
  final String description;
  final String myRole; // (MỚI)
  final String? lastMessageContent;
  final DateTime? lastMessageTimestamp;
  final String? lastMessageSender; 
  final String? avatarUrl; // (MỚI)

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.myRole, // (MỚI)
    this.lastMessageContent, 
    this.lastMessageTimestamp,
    this.lastMessageSender, 
    this.avatarUrl, // (MỚI)
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['group_id'],
      name: json['group_name'],
      description: json['description'] ?? '',
      myRole: json['my_role'], // (MỚI) Đọc vai trò
      
      lastMessageContent: json['last_message_content'],
      lastMessageTimestamp: json['last_message_timestamp'] != null
          ? DateTime.parse(json['last_message_timestamp'])
          : null,
      lastMessageSender: json['last_message_sender'], 
      avatarUrl: json['avatarUrl'], // (MỚI) Đọc avatar
    );
  }
}