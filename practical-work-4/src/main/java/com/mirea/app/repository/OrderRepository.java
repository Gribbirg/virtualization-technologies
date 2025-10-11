package com.mirea.app.repository;

import com.mirea.app.entity.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByUserId(Long userId);
    List<Order> findByStatus(String status);

    @Query("SELECT o FROM Order o WHERE o.user.username = :username")
    List<Order> findByUserUsername(String username);
}