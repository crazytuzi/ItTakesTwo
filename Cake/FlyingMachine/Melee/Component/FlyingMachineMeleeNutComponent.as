
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeNut;

class UFlyingMachineMeleeNutComponent : UFlyingMachineMeleeComponent
{
	default bIsValidAsTarget = false;

	const float ForwardSpeed = 850.f;

	AFlyingMachineMeleeNut NutOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		NutOwner = Cast<AFlyingMachineMeleeNut>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnValidImpactToTarget(UHazeMeleeImpactAsset ImpactAsset)
	{
		NutOwner.bHasImpactedWithTarget = true;
		Game::GetMay().SetCapabilityActionState(n"OnNutImpact", EHazeActionState::ActiveForOneFrame);
	}

	// UFUNCTION(BlueprintOverride)
	// void PrepareNextFrame()
	// {	
	// 	// if(!bIsAttached && MoveTime > 1.f)
	// 	// {
	// 	// 	FVector CurrentRelativeLocation = Owner.RootComponent.RelativeLocation;
	// 	// 	if(CurrentRelativeLocation.DistSquared(LastRelativeLocation) <= KINDA_SMALL_NUMBER || MoveTime > 3.f)
	// 	// 		NutOwner.DisableActor(nullptr);

	// 	// 	LastRelativeLocation = CurrentRelativeLocation;
	// 	// }
	// }
}