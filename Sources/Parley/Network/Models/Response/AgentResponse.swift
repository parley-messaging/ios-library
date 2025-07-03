struct AgentResponse: Equatable, Codable {
    let id: Int
    let name: String?
    let avatar: String?
    
    func toDomainModel() -> Agent {
        Agent(id: id, name: name, avatar: avatar)
    }
    
    static func from(_ agent: Agent) -> Self {
        Self(id: agent.id, name: agent.name, avatar: agent.avatar)
    }
    
    static func from(_ agent: Agent?) -> StoredAgent? {
        guard let agent else { return nil }
        return Self.from(agent)
    }
}
