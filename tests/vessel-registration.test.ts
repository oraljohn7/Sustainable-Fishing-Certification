import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity VM environment
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  block: {
    time: 1625097600, // July 1, 2021
  },
}

// Mock the contract functions
const vesselRegistration = {
  registerVessel: vi.fn(),
  addEquipment: vi.fn(),
  addCertification: vi.fn(),
  updateVesselStatus: vi.fn(),
  updateCertificationStatus: vi.fn(),
  getVessel: vi.fn(),
  getEquipment: vi.fn(),
  getCertification: vi.fn(),
  transferOwnership: vi.fn(),
}

describe("Vessel Registration Contract", () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks()
    
    // Setup default mock implementations
    vesselRegistration.registerVessel.mockReturnValue({ type: "ok", value: true })
    vesselRegistration.addEquipment.mockReturnValue({ type: "ok", value: true })
    vesselRegistration.addCertification.mockReturnValue({ type: "ok", value: true })
    vesselRegistration.updateVesselStatus.mockReturnValue({ type: "ok", value: true })
    vesselRegistration.updateCertificationStatus.mockReturnValue({ type: "ok", value: true })
    vesselRegistration.transferOwnership.mockReturnValue({ type: "ok", value: true })
    
    vesselRegistration.getVessel.mockReturnValue({
      value: {
        owner: mockClarity.tx.sender,
        name: "Test Vessel",
        registrationNumber: "REG123456",
        vesselType: "trawler",
        length: 25,
        capacity: 100,
        homePort: "Test Port",
        registrationDate: mockClarity.block.time,
        licenseExpiry: mockClarity.block.time + 31536000, // 1 year later
        active: true,
      },
    })
    
    vesselRegistration.getEquipment.mockReturnValue({
      value: {
        equipmentType: "gps",
        description: "GPS Navigation System",
        installationDate: mockClarity.block.time - 2592000, // 30 days ago
        lastInspection: mockClarity.block.time,
        inspector: mockClarity.tx.sender,
      },
    })
    
    vesselRegistration.getCertification.mockReturnValue({
      value: {
        certificationType: "safety",
        issuer: "Maritime Safety Authority",
        issueDate: mockClarity.block.time - 5184000, // 60 days ago
        expiryDate: mockClarity.block.time + 31536000, // 1 year later
        status: "active",
      },
    })
  })
  
  describe("registerVessel", () => {
    it("should register a new vessel successfully", () => {
      const vesselId = "vessel-001"
      const name = "Test Vessel"
      const registrationNumber = "REG123456"
      const vesselType = "trawler"
      const length = 25
      const capacity = 100
      const homePort = "Test Port"
      const licenseExpiry = mockClarity.block.time + 31536000 // 1 year later
      
      const result = vesselRegistration.registerVessel(
          vesselId,
          name,
          registrationNumber,
          vesselType,
          length,
          capacity,
          homePort,
          licenseExpiry,
      )
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
      expect(vesselRegistration.registerVessel).toHaveBeenCalledWith(
          vesselId,
          name,
          registrationNumber,
          vesselType,
          length,
          capacity,
          homePort,
          licenseExpiry,
      )
    })
  })
  
  describe("addEquipment", () => {
    it("should add equipment to a vessel", () => {
      const vesselId = "vessel-001"
      const equipmentId = "equipment-001"
      const equipmentType = "gps"
      const description = "GPS Navigation System"
      const installationDate = mockClarity.block.time - 2592000 // 30 days ago
      
      const result = vesselRegistration.addEquipment(
          vesselId,
          equipmentId,
          equipmentType,
          description,
          installationDate,
      )
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
      expect(vesselRegistration.addEquipment).toHaveBeenCalledWith(
          vesselId,
          equipmentId,
          equipmentType,
          description,
          installationDate,
      )
    })
  })
  
  describe("addCertification", () => {
    it("should add certification to a vessel", () => {
      const vesselId = "vessel-001"
      const certificationId = "cert-001"
      const certificationType = "safety"
      const issuer = "Maritime Safety Authority"
      const issueDate = mockClarity.block.time - 5184000 // 60 days ago
      const expiryDate = mockClarity.block.time + 31536000 // 1 year later
      
      const result = vesselRegistration.addCertification(
          vesselId,
          certificationId,
          certificationType,
          issuer,
          issueDate,
          expiryDate,
      )
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
      expect(vesselRegistration.addCertification).toHaveBeenCalledWith(
          vesselId,
          certificationId,
          certificationType,
          issuer,
          issueDate,
          expiryDate,
      )
    })
  })
  
  describe("updateVesselStatus", () => {
    it("should update vessel status", () => {
      const vesselId = "vessel-001"
      const active = false
      
      const result = vesselRegistration.updateVesselStatus(vesselId, active)
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
      expect(vesselRegistration.updateVesselStatus).toHaveBeenCalledWith(vesselId, active)
    })
  })
  
  describe("getVessel", () => {
    it("should retrieve vessel information", () => {
      const vesselId = "vessel-001"
      
      const result = vesselRegistration.getVessel(vesselId)
      
      expect(result.value).toEqual({
        owner: mockClarity.tx.sender,
        name: "Test Vessel",
        registrationNumber: "REG123456",
        vesselType: "trawler",
        length: 25,
        capacity: 100,
        homePort: "Test Port",
        registrationDate: mockClarity.block.time,
        licenseExpiry: mockClarity.block.time + 31536000,
        active: true,
      })
      expect(vesselRegistration.getVessel).toHaveBeenCalledWith(vesselId)
    })
  })
})

