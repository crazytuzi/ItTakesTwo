
class UChangeCharacterMeshCapability : UHazeCapability
{
	default RespondToEvent(n"NeverActivate");

	// Mesh the character should change to while it has this capability
	UPROPERTY(Category = "Mesh")
	USkeletalMesh SkeletalMesh;

	private USkeletalMesh PreviousMesh;

 	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		auto Character = Cast<AHazeCharacter>(Owner);
		if (Character != nullptr)
		{
			PreviousMesh = Character.Mesh.GetSkeletalMesh();

			// Reset all override materials
			int MaterialCount = Character.Mesh.NumMaterials;
			for (int i = 0; i < MaterialCount; ++i)
				Character.Mesh.SetMaterial(i, nullptr);

			// Change the skeletal mesh
			Character.Mesh.SetSkeletalMesh(SkeletalMesh);
		}
	}

 	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		auto Character = Cast<AHazeCharacter>(Owner);
		auto CharacterCDO = Cast<AHazeCharacter>(Owner.Class.DefaultObject);
		if (Character != nullptr && CharacterCDO != nullptr)
		{
			// Reset all override materials
			int MaterialCount = Character.Mesh.NumMaterials;
			for (int i = 0; i < MaterialCount; ++i)
				Character.Mesh.SetMaterial(i, nullptr);

			// Change the skeletal mesh
			Character.Mesh.SetSkeletalMesh(CharacterCDO.Mesh.SkeletalMesh);
		}
	}
};