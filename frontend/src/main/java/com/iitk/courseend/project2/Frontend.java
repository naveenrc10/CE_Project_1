package com.iitk.courseend.project2;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.client.RestTemplate;
import org.springframework.beans.factory.annotation.Value;

@Controller
public class Frontend {

	private final RestTemplate restTemplate;

	public Frontend(RestTemplate restTemplate) {
		this.restTemplate = restTemplate;
	}

	@Value("${service.url}")
	private String apiServiceUrl;

	@GetMapping("/")
	public String showForm() {
		return "form";
	}

	@GetMapping("/submit")
	public String handleGetSubmit() {
		return "redirect:/";
	}

	@PostMapping("/submit")
	public String handleForm(@RequestParam("inputText") String inputText, Model model) {
		System.out.println(inputText);
		
		 String apiUrl = apiServiceUrl + "?inputText=" + inputText;
		 System.out.println(apiUrl);
		 String apiResponse = restTemplate.getForObject(apiUrl, String.class);
		model.addAttribute("result", apiResponse);
		return "result";
	}
}