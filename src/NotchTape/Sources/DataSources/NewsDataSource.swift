import Foundation

struct NewsItem {
    let title: String
    let source: String
    let url: String?
    let publishedAt: Date
}

class NewsDataSource: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    private var timer: Timer?
    
    init() {
        fetchNews()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            self.fetchNews()
        }
    }
    
    func fetchNews() {
        // Using Hacker News API as it's free and doesn't require API key
        fetchHackerNews()
    }
    
    private func fetchHackerNews() {
        let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { 
                DispatchQueue.main.async {
                    self?.useDemoNews()
                }
                return 
            }
            
            do {
                let storyIds = try JSONDecoder().decode([Int].self, from: data)
                let topStoryIds = Array(storyIds.prefix(30)) // Get top 30 stories for more variety
                
                // Fetch details for each story
                let group = DispatchGroup()
                var stories: [NewsItem] = []
                
                for storyId in topStoryIds {
                    group.enter()
                    self?.fetchHackerNewsStory(id: storyId) { story in
                        if let story = story {
                            stories.append(story)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self?.newsItems = stories.sorted { $0.publishedAt > $1.publishedAt }
                    print("✅ Fetched \(stories.count) real news items from Hacker News")
                }
                
            } catch {
                print("Error fetching HN stories: \(error)")
                DispatchQueue.main.async {
                    self?.useDemoNews()
                }
            }
        }.resume()
    }
    
    private func fetchHackerNewsStory(id: Int, completion: @escaping (NewsItem?) -> Void) {
        let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { 
                completion(nil)
                return 
            }
            
            do {
                let story = try JSONDecoder().decode(HNStory.self, from: data)
                let newsItem = NewsItem(
                    title: story.title ?? "Untitled",
                    source: "Hacker News",
                    url: story.url,
                    publishedAt: Date(timeIntervalSince1970: TimeInterval(story.time ?? 0))
                )
                completion(newsItem)
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    private func useDemoNews() {
        newsItems = [
            NewsItem(title: "Apple Announces New AI Features", source: "TechCrunch", url: nil, publishedAt: Date()),
            NewsItem(title: "Stock Market Hits New Highs", source: "Bloomberg", url: nil, publishedAt: Date().addingTimeInterval(-3600)),
            NewsItem(title: "SpaceX Successfully Launches Mission", source: "SpaceNews", url: nil, publishedAt: Date().addingTimeInterval(-7200)),
            NewsItem(title: "New Programming Language Released", source: "GitHub Blog", url: nil, publishedAt: Date().addingTimeInterval(-10800))
        ]
    }
}

struct HNStory: Codable {
    let title: String?
    let url: String?
    let time: Int?
}