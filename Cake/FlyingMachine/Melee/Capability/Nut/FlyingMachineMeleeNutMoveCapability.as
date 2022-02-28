
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeNutComponent;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeNut;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;

class UFlyingMachineMeleeNutMoveCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	
	default CapabilityDebugCategory = MeleeTags::Melee;

	const float InitalOffset = 100.f;

	AFlyingMachineMeleeNut Nut = nullptr;
	UFlyingMachineMeleeNutComponent NutMeleeComponent = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelComponent = nullptr;
	FVector Scale = FVector::ZeroVector;
	bool bApplyInitialAmount = false;
	float CurrentMoveSpeed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Nut = Cast<AFlyingMachineMeleeNut>(Owner);
		NutMeleeComponent = UFlyingMachineMeleeNutComponent::Get(Nut);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Nut.bIsAttached)
		 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		SquirrelComponent = UFlyingMachineMeleeSquirrelComponent::Get(Owner.GetOwner());
		ensure(SquirrelComponent != nullptr);

		if(SquirrelComponent.IsFacingRight())
			FaceRightLocal();	
		else
			FaceLeftLocal();

		Nut.LastRelativeLocation = Nut.RootComponent.GetRelativeLocation();
		NutMeleeComponent.AddImpactInstigator(Nut.MovingImpactAsset, FHazeMeleeImpactEffectParams());
		bApplyInitialAmount = false;
		CurrentMoveSpeed = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		NutMeleeComponent.RemoveImpactInstigator();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MoveAmount = 0;
		if(IsFacingRight())
		{	
			MoveAmount = CurrentMoveSpeed * DeltaTime;	
			if(bApplyInitialAmount)
				MoveAmount -= InitalOffset;
		}
		else
		{
			MoveAmount = -CurrentMoveSpeed * DeltaTime;
			if(bApplyInitialAmount)
				MoveAmount += InitalOffset;
		}

		bApplyInitialAmount = false;
		MeleeComponent.AddDeltaMovement(n"NutMove", MoveAmount, 0.f);
		Nut.MoveTime += DeltaTime;
		MeleeComponent.UpdateControlSideImpact();

		CurrentMoveSpeed = FMath::FInterpTo(CurrentMoveSpeed, NutMeleeComponent.ForwardSpeed, DeltaTime, 10.f);

		EHazeUpdateSplineStatusType UpdateType = EHazeUpdateSplineStatusType::MAX;
		MeleeComponent.PeekPosition(-1.f * FMath::Sign(MoveAmount), UpdateType);
		if(UpdateType == EHazeUpdateSplineStatusType::AtEnd)
		{
			Nut.MoveTime = BIG_NUMBER;
		}
	}
}
