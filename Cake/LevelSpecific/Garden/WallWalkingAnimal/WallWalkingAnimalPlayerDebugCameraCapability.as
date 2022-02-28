import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;
import Vino.Camera.Capabilities.DebugCameraCapability;


class UWallWalkingAnimalPlayerDebugCameraCapability : UDebugCameraCapability
{
	default bIsDefault = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		SetMutuallyExclusive(n"DebugCamera", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()override
	{
		Super::OnRemoved();
		SetMutuallyExclusive(n"DebugCamera", false);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Super::OnActivated(ActivationParams);
		PlayerOwner.BlockCapabilities(n"SpiderCamera", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		Super::OnDeactivated(DeactivationParams);
		PlayerOwner.UnblockCapabilities(n"SpiderCamera", this);
	}

	void TeleportOwner(FVector Loc, FVector ImpactNormal, float Yaw) override
	{
		auto AnimalComp = UWallWalkingAnimalComponent::Get(PlayerOwner);
		if(AnimalComp.CurrentAnimal != nullptr)
			AnimalComp.CurrentAnimal.TeleportActor(Location = Loc, Rotation = FRotator(0.f, Yaw, 0.f));
		else
			Super::TeleportOwner(Loc, ImpactNormal, Yaw);

		FixupDebugLocation(AnimalComp, Loc, ImpactNormal);
	}

	void TeleportOtherPlayer(FVector Loc, FVector ImpactNormal, float Yaw) override
	{
		auto AnimalComp = UWallWalkingAnimalComponent::Get(PlayerOwner.GetOtherPlayer());
		if(AnimalComp.CurrentAnimal != nullptr)
			AnimalComp.CurrentAnimal.TeleportActor(Location = Loc, Rotation = FRotator(0.f, Yaw, 0.f));
		else
			Super::TeleportOtherPlayer(Loc, ImpactNormal, Yaw);

		FixupDebugLocation(AnimalComp, Loc, ImpactNormal);
	}

	void FixupDebugLocation(UWallWalkingAnimalComponent AnimalComp, FVector Loc, FVector ImpactNormal)
	{
		const FVector2D CollisionSize = AnimalComp.CurrentAnimal.GetCollisionSize();
		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(AnimalComp.CurrentAnimal.MoveComp);
		TraceParams.From = Loc + (ImpactNormal * CollisionSize.Y);
		TraceParams.To = Loc - (ImpactNormal * CollisionSize.Y);
		TraceParams.SetToLineTrace();

		AnimalComp.CurrentAnimal.ChangeActorWorldUp(ImpactNormal);
		FRotator NewMeshRotation = Math::MakeRotFromYZ(AnimalComp.CurrentAnimal.GetActorRightVector().ConstrainToPlane(ImpactNormal).GetSafeNormal(), ImpactNormal);
		AnimalComp.CurrentAnimal.Mesh.SetWorldRotation(NewMeshRotation);
		PlayerOwner.ChangeActorWorldUp(ImpactNormal);
	}
}
