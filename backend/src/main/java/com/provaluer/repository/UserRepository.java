package com.provaluer.repository;

import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByEmailIgnoreCase(String email);
    List<User> findAllByRole(UserRole role);
    List<User> findAllByDeleted(boolean deleted);
    List<User> findAllByRoleIn(List<UserRole> roles);

    @Query("SELECT u FROM User u WHERE u.deleted = false ORDER BY u.createdAt DESC")
    List<User> findAllActive();

    @Query("SELECT u FROM User u WHERE u.deleted = true ORDER BY u.deletedAt DESC")
    List<User> findAllSoftDeleted();
}
