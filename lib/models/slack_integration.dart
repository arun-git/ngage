import 'enums.dart';

/// Slack workspace configuration for a group
class SlackIntegration {
  final String id;
  final String groupId;
  final String workspaceId;
  final String workspaceName;
  final String botToken;
  final String? userToken;
  final SlackIntegrationType integrationType;
  final Map<String, String> channelMappings; // notification type -> channel ID
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SlackIntegration({
    required this.id,
    required this.groupId,
    required this.workspaceId,
    required this.workspaceName,
    required this.botToken,
    this.userToken,
    required this.integrationType,
    required this.channelMappings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SlackIntegration.fromJson(Map<String, dynamic> json) {
    return SlackIntegration(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      workspaceId: json['workspaceId'] as String,
      workspaceName: json['workspaceName'] as String,
      botToken: json['botToken'] as String,
      userToken: json['userToken'] as String?,
      integrationType: SlackIntegrationType.fromString(json['integrationType'] as String),
      channelMappings: Map<String, String>.from(json['channelMappings'] as Map),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'botToken': botToken,
      'userToken': userToken,
      'integrationType': integrationType.value,
      'channelMappings': channelMappings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SlackIntegration copyWith({
    String? id,
    String? groupId,
    String? workspaceId,
    String? workspaceName,
    String? botToken,
    String? userToken,
    SlackIntegrationType? integrationType,
    Map<String, String>? channelMappings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SlackIntegration(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      botToken: botToken ?? this.botToken,
      userToken: userToken ?? this.userToken,
      integrationType: integrationType ?? this.integrationType,
      channelMappings: channelMappings ?? this.channelMappings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Slack channel information
class SlackChannel {
  final String id;
  final String name;
  final bool isPrivate;
  final bool isMember;

  const SlackChannel({
    required this.id,
    required this.name,
    required this.isPrivate,
    required this.isMember,
  });

  factory SlackChannel.fromJson(Map<String, dynamic> json) {
    return SlackChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      isPrivate: json['is_private'] as bool? ?? false,
      isMember: json['is_member'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_private': isPrivate,
      'is_member': isMember,
    };
  }
}

/// Slack user information from OAuth
class SlackUser {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String teamId;
  final String teamName;

  const SlackUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.teamId,
    required this.teamName,
  });

  factory SlackUser.fromJson(Map<String, dynamic> json) {
    return SlackUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'team_id': teamId,
      'team_name': teamName,
    };
  }
}

/// Slack message payload for sending notifications
class SlackMessage {
  final String channel;
  final String text;
  final List<SlackBlock>? blocks;
  final List<SlackAttachment>? attachments;
  final SlackMessageType messageType;
  final Map<String, dynamic>? metadata;

  const SlackMessage({
    required this.channel,
    required this.text,
    this.blocks,
    this.attachments,
    required this.messageType,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'channel': channel,
      'text': text,
      'message_type': messageType.value,
    };

    if (blocks != null) {
      json['blocks'] = blocks!.map((block) => block.toJson()).toList();
    }

    if (attachments != null) {
      json['attachments'] = attachments!.map((attachment) => attachment.toJson()).toList();
    }

    if (metadata != null) {
      json['metadata'] = metadata;
    }

    return json;
  }
}

/// Slack block for rich message formatting
class SlackBlock {
  final String type;
  final Map<String, dynamic> data;

  const SlackBlock({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...data,
    };
  }

  // Factory constructors for common block types
  factory SlackBlock.section({required String text}) {
    return SlackBlock(
      type: 'section',
      data: {
        'text': {
          'type': 'mrkdwn',
          'text': text,
        },
      },
    );
  }

  factory SlackBlock.divider() {
    return const SlackBlock(
      type: 'divider',
      data: {},
    );
  }

  factory SlackBlock.header({required String text}) {
    return SlackBlock(
      type: 'header',
      data: {
        'text': {
          'type': 'plain_text',
          'text': text,
        },
      },
    );
  }
}

/// Slack attachment for legacy message formatting
class SlackAttachment {
  final String? color;
  final String? title;
  final String? text;
  final List<SlackField>? fields;

  const SlackAttachment({
    this.color,
    this.title,
    this.text,
    this.fields,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (color != null) json['color'] = color;
    if (title != null) json['title'] = title;
    if (text != null) json['text'] = text;
    if (fields != null) {
      json['fields'] = fields!.map((field) => field.toJson()).toList();
    }

    return json;
  }
}

/// Slack field for attachment formatting
class SlackField {
  final String title;
  final String value;
  final bool short;

  const SlackField({
    required this.title,
    required this.value,
    this.short = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'short': short,
    };
  }
}

/// OAuth response from Slack
class SlackOAuthResponse {
  final bool ok;
  final String? accessToken;
  final String? scope;
  final String? userId;
  final String? teamId;
  final String? teamName;
  final SlackUser? user;
  final String? error;

  const SlackOAuthResponse({
    required this.ok,
    this.accessToken,
    this.scope,
    this.userId,
    this.teamId,
    this.teamName,
    this.user,
    this.error,
  });

  factory SlackOAuthResponse.fromJson(Map<String, dynamic> json) {
    return SlackOAuthResponse(
      ok: json['ok'] as bool,
      accessToken: json['access_token'] as String?,
      scope: json['scope'] as String?,
      userId: json['user_id'] as String?,
      teamId: json['team_id'] as String?,
      teamName: json['team_name'] as String?,
      user: json['user'] != null ? SlackUser.fromJson(json['user'] as Map<String, dynamic>) : null,
      error: json['error'] as String?,
    );
  }
}