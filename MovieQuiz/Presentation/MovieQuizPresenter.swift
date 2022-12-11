//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Ruslan Batalov on 11.12.2022.
//



import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    private let statisticService: StatisticService!
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    var correctanswerQuestion: Int = 0
    var currentQuestion: QuizQuestion?
//
    private var questionFactory: QuestionFactoryProtocol?
    weak var viewController: MovieQuizViewController?
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        statisticService = StatisticServiceImplementation()
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
        
    }
    
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message = error.localizedDescription
        viewController?.showNetworkError(message: message)
    }
    
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctanswerQuestion = 0
        questionFactory?.requestNextQuestion()
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
}
    func didAnswerQuestion(isCorrect: Bool) {
        if isCorrect {
            correctanswerQuestion += 1
            
        }
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {return}
        let givenAnswer = isYes
        proceedWithAnswer(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    func didRecieveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {return}
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    func proceedToNextQuestionResults(){
        
        if self.isLastQuestion(){
            self.statisticService?.store(correct: correctanswerQuestion, total: questionsAmount)
            
            
            let text = "Ваш результат: \(correctanswerQuestion)/\(questionsAmount) \n Количество сыграных квизов: \(self.statisticService?.gamesCount ?? 0) \n      Рекорд: \(self.statisticService?.bestGame.correct ?? 0)/\(questionsAmount) (\(self.statisticService?.bestGame.date.dateTimeString ?? Date().dateTimeString )) \n Средняя точность: \(String(format: "%.2f", 100*(self.statisticService?.totalAccuracy ?? 0)/Double(self.statisticService?.gamesCount ?? 0)))%"
            let viewModel = QuizResultsViewModel(title: "Этот раунд окончен!",
                                                 text: text,
                                                 buttonText: "Сыграть еще раз")
            self.correctanswerQuestion = 0
            self.viewController?.show(quiz: viewModel)
        }
                    else {
                        self.switchToNextQuestion()
                        self.questionFactory?.requestNextQuestion()
        }
    }
    func proceedWithAnswer(isCorrect: Bool) {
        
        didAnswerQuestion(isCorrect: isCorrect)
        
        viewController?.hightLightImageBorder(isCorrectAnswer: isCorrect)
        
//        imageView.layer.masksToBounds = true
//        imageView.layer.borderWidth = 8
//        imageView.layer.borderColor = isCorrect ? UIColor(named: "YP Green")?.cgColor : UIColor(named: "YP Red")?.cgColor
//        imageView.layer.cornerRadius = 20
        self.viewController?.yesbutton.isEnabled = false
        self.viewController?.nobutton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            
            guard let self = self else{return}
            self.viewController?.yesbutton.isEnabled = true
            self.viewController?.nobutton.isEnabled = true
            self.viewController?.imageView.layer.borderColor = UIColor.clear.cgColor
//
////            self.presenter.questionFactory = self.questionFactory
            self.proceedToNextQuestionResults()
        }
        
    }
    
    
}


