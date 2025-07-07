class ApiEndpoints {
  // Base URL
  static const String baseUrl = "http://api.inovact.in:3000/v1";
  static const String socketUrl = 'http://api.inovact.in:3002/';

  // User Endpoints
  static const String users = "$baseUrl/users";
  static const String user = "$baseUrl/user";
  static const String userIdea = "$user/idea";
  static const String userPost = "$user/post";
  static const String deleteProject = "$baseUrl/post";
  static const String deleteIdea = "$baseUrl/idea";
  static const String deleteThought = "$baseUrl/thoughts";
  static const String userTeam = "$user/team";
  static const String userThought = "$user/thought";
  static const String userInterest = "$user/interest";
    static const String userFeedback = "$user/feedback";
      static const String userDeactivate = "$user/deactivate";

  //Leaderboard
   static const String leaderboard= "$baseUrl/leaderboard";
   static const String activity = "$baseUrl/user/activities";

  // Notifications
  static const String notifications = "$baseUrl/notifications";
  static const String notificationsMarkAsRead = "$notifications/markasread";
  static const String fcmToken = "$baseUrl/fcm/token";

  // Idea Endpoints
  static const String idea = "$baseUrl/idea";
  static String ideaLike(int ideaId) => "$idea/like?idea_id=$ideaId";

  // Post Endpoints
  static const String post = "$baseUrl/post";
  static String postById(int postId) => "$post?id=$postId";
  static String postLike(int projectId) => "$post/like?project_id=$projectId";

  // Team Endpoints
  static const String team = "$baseUrl/team";
  static const String request = "$baseUrl/team/request";
  static const String teamRequestAccept = "$team/request/accept";
  static const String teamRequestReject = "$team/request/reject";
  static const String teamInvite = "$team/invite";
  static const String teamInviteAccept = "$team/invite/accept";
  static const String teamInviteReject = "$team/invite/reject";
  static const String teamDocuments = "$team/documents";
  static const String teamMember = "$team/member";
  static const String teamToggleAdmin = "$team/member/toggleadmin";
  static String getTeam(int teamId) => "$team/?team_id=$teamId";

  static String teamDownload = "$team/documents/download";

  static String teamMessages(int teamId, String timeStamp, int limit) =>
      "$team/messages?team_id=$teamId&timeStamp=$timeStamp&limit=$limit";

  // Connections Endpoints
  static const String connections = "http://api.inovact.in:3000/v1/connections";
  static const String requests = "http://api.inovact.in:3000/v1/requests";

  static String connectionRequest(int userId) =>
      "$connections/request?user_id=$userId";
  static String connectionAccept(int userId) =>
      "$connections/accept?user_id=$userId";
  static String connectionReject(int userId) =>
      "$connections/reject?user_id=$userId";
  static String connectionRemove(int userId) =>
      "$connections/remove?user_id=$userId";
  static const String connectionStatistics = "$connections/statistics";

  // Thoughts Endpoints
  static const String thoughts = "$baseUrl/thoughts";
  static String thoughtById(int thoughtId) => "$thoughts?id=$thoughtId";
  static String thoughtLike(int thoughtId) =>
      "$thoughts/like?thought_id=$thoughtId";

  // Skills and Comments
  static const String skills = "$baseUrl/skills";
  static const String comment = "$baseUrl/comment";


  // Messaging
  static const String messagingPrivate = "$baseUrl/messaging/private";
  static const String messagingUsers =
      "http://api.inovact.in:3000/v1/messaging/users";

  static String privateMessages(int userId) =>
      "$messagingPrivate?user_id=$userId";
}
