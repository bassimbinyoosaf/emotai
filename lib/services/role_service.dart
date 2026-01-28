enum UserRole { admin, user }

class RoleService {
  static const adminEmails = [
    'bassim23.dev@gmail.com',
    'bassimbinyoosaf55@gmail.com',
  ];

  static UserRole getRole(String email) {
    return adminEmails.contains(email.toLowerCase())
        ? UserRole.admin
        : UserRole.user;
  }
}
