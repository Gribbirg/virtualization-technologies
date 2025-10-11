package com.mirea.app.controller;

import com.mirea.app.entity.Order;
import com.mirea.app.entity.Product;
import com.mirea.app.entity.User;
import com.mirea.app.repository.OrderRepository;
import com.mirea.app.repository.ProductRepository;
import com.mirea.app.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private static final Logger logger = LoggerFactory.getLogger(OrderController.class);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductRepository productRepository;

    @PostMapping
    public ResponseEntity<Order> createOrder(@RequestBody OrderRequest orderRequest) {
        logger.info("Creating new order for user ID: {}", orderRequest.getUserId());

        Optional<User> user = userRepository.findById(orderRequest.getUserId());
        if (!user.isPresent()) {
            logger.error("User not found with ID: {}", orderRequest.getUserId());
            return ResponseEntity.badRequest().build();
        }

        Order order = new Order();
        order.setUser(user.get());
        order.setOrderDate(LocalDateTime.now());
        order.setStatus("PENDING");
        order.setTotalAmount(orderRequest.getTotalAmount());

        if (orderRequest.getProductIds() != null && !orderRequest.getProductIds().isEmpty()) {
            List<Product> products = productRepository.findAllById(orderRequest.getProductIds());
            order.setProducts(products);
        }

        Order savedOrder = orderRepository.save(order);
        logger.info("Order created with ID: {}", savedOrder.getId());
        return ResponseEntity.ok(savedOrder);
    }

    @GetMapping
    public ResponseEntity<List<Order>> getAllOrders() {
        logger.info("Fetching all orders");
        List<Order> orders = orderRepository.findAll();
        logger.info("Retrieved {} orders", orders.size());
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Order> getOrderById(@PathVariable Long id) {
        logger.info("Fetching order by ID: {}", id);
        Optional<Order> order = orderRepository.findById(id);
        if (order.isPresent()) {
            logger.info("Order found with ID: {}", order.get().getId());
            return ResponseEntity.ok(order.get());
        } else {
            logger.warn("Order not found with ID: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<Order> updateOrder(@PathVariable Long id, @RequestBody OrderUpdateRequest updateRequest) {
        logger.info("Updating order with ID: {}", id);
        Optional<Order> optionalOrder = orderRepository.findById(id);
        if (optionalOrder.isPresent()) {
            Order order = optionalOrder.get();
            if (updateRequest.getStatus() != null) {
                order.setStatus(updateRequest.getStatus());
            }
            if (updateRequest.getTotalAmount() != null) {
                order.setTotalAmount(updateRequest.getTotalAmount());
            }
            Order updatedOrder = orderRepository.save(order);
            logger.info("Order updated with ID: {}", updatedOrder.getId());
            return ResponseEntity.ok(updatedOrder);
        } else {
            logger.warn("Order not found for update with ID: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteOrder(@PathVariable Long id) {
        logger.info("Deleting order with ID: {}", id);
        if (orderRepository.existsById(id)) {
            orderRepository.deleteById(id);
            logger.info("Order deleted with ID: {}", id);
            return ResponseEntity.noContent().build();
        } else {
            logger.warn("Order not found for deletion with ID: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Order>> getOrdersByUserId(@PathVariable Long userId) {
        logger.info("Fetching orders for user ID: {}", userId);
        List<Order> orders = orderRepository.findByUserId(userId);
        logger.info("Found {} orders for user ID: {}", orders.size(), userId);
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<Order>> getOrdersByStatus(@PathVariable String status) {
        logger.info("Fetching orders with status: {}", status);
        List<Order> orders = orderRepository.findByStatus(status);
        logger.info("Found {} orders with status: {}", orders.size(), status);
        return ResponseEntity.ok(orders);
    }

    public static class OrderRequest {
        private Long userId;
        private BigDecimal totalAmount;
        private List<Long> productIds;

        public Long getUserId() { return userId; }
        public void setUserId(Long userId) { this.userId = userId; }
        public BigDecimal getTotalAmount() { return totalAmount; }
        public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
        public List<Long> getProductIds() { return productIds; }
        public void setProductIds(List<Long> productIds) { this.productIds = productIds; }
    }

    public static class OrderUpdateRequest {
        private String status;
        private BigDecimal totalAmount;

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public BigDecimal getTotalAmount() { return totalAmount; }
        public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    }
}