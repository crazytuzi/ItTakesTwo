import Vino.Characters.ChangeCharacterMeshCapability;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

class UMusicalFlyingChangeMeshCapability : UChangeCharacterMeshCapability
{
 	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		auto Character = Cast<AHazePlayerCharacter>(Owner);
		UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(Owner);
		if (Character != nullptr && FlyingComp.FlyingSkeletalMesh != nullptr)
		{
			SkeletalMesh = FlyingComp.FlyingSkeletalMesh;
			Super::Setup(SetupParams);
		}
	}
}
