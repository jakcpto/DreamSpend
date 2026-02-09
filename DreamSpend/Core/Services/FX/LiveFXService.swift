import Foundation

struct LiveFXService {
    private struct Response: Decodable {
        let rates: [String: Decimal]
    }

    func fetchRate(from source: String, to target: String) async throws -> Decimal {
        let query = "from=\(source)&to=\(target)"
        guard let url = URL(string: "https://api.frankfurter.app/latest?\(query)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let rate = decoded.rates[target], rate > 0 else {
            throw URLError(.cannotParseResponse)
        }

        return rate
    }
}
