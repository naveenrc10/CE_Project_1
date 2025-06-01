package com.iitk.courseend.project2;

import org.springframework.web.bind.annotation.*;

@RestController
public class Backend {
	@GetMapping("/api/Greeting")
	public String handleForm(@RequestParam("inputText") String inputText) {
		return "hello " + inputText;
	}

    @GetMapping("/")
	public String handleForm() {
		return "";
	}
}
