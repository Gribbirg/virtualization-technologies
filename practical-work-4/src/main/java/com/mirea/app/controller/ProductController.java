package com.mirea.app.controller;

import com.mirea.app.entity.Product;
import com.mirea.app.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private static final Logger logger = LoggerFactory.getLogger(ProductController.class);

    @Autowired
    private ProductRepository productRepository;

    @PostMapping
    public ResponseEntity<Product> createProduct(@RequestBody Product product) {
        logger.info("Creating new product: {}", product.getName());
        Product savedProduct = productRepository.save(product);
        logger.info("Product created with ID: {}", savedProduct.getId());
        return ResponseEntity.ok(savedProduct);
    }

    @GetMapping
    public ResponseEntity<List<Product>> getAllProducts() {
        logger.info("Fetching all products");
        List<Product> products = productRepository.findAll();
        logger.info("Retrieved {} products", products.size());
        return ResponseEntity.ok(products);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable Long id) {
        logger.info("Fetching product by ID: {}", id);
        Optional<Product> product = productRepository.findById(id);
        if (product.isPresent()) {
            logger.info("Product found: {}", product.get().getName());
            return ResponseEntity.ok(product.get());
        } else {
            logger.warn("Product not found with ID: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<Product> updateProduct(@PathVariable Long id, @RequestBody Product productDetails) {
        logger.info("Updating product with ID: {}", id);
        Optional<Product> optionalProduct = productRepository.findById(id);
        if (optionalProduct.isPresent()) {
            Product product = optionalProduct.get();
            product.setName(productDetails.getName());
            product.setDescription(productDetails.getDescription());
            product.setPrice(productDetails.getPrice());
            product.setStock(productDetails.getStock());
            Product updatedProduct = productRepository.save(product);
            logger.info("Product updated: {}", updatedProduct.getName());
            return ResponseEntity.ok(updatedProduct);
        } else {
            logger.warn("Product not found for update with ID: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        logger.info("Deleting product with ID: {}", id);
        if (productRepository.existsById(id)) {
            productRepository.deleteById(id);
            logger.info("Product deleted with ID: {}", id);
            return ResponseEntity.noContent().build();
        } else {
            logger.warn("Product not found for deletion with ID: {}", id);
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<Product>> searchProductsByName(@RequestParam String name) {
        logger.info("Searching products by name: {}", name);
        List<Product> products = productRepository.findByNameContainingIgnoreCase(name);
        logger.info("Found {} products matching '{}'", products.size(), name);
        return ResponseEntity.ok(products);
    }

    @GetMapping("/in-stock")
    public ResponseEntity<List<Product>> getProductsInStock(@RequestParam(defaultValue = "0") Integer minStock) {
        logger.info("Fetching products with stock > {}", minStock);
        List<Product> products = productRepository.findByStockGreaterThan(minStock);
        logger.info("Found {} products in stock", products.size());
        return ResponseEntity.ok(products);
    }
}