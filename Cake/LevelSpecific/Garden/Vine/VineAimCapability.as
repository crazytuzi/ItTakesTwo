import Cake.LevelSpecific.Garden.Vine.VineComponent;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Peanuts.Aiming.AutoAimStatics;

class UVineAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(CapabilityTags::CharacterFacing);
	default CapabilityTags.Add(n"BlockedWhileGrinding");
	default CapabilityTags.Add(n"Vine");
	
	default CapabilityDebugCategory = n"LevelSpecific";
	
	// This needs to tick after vineactive capability, else the camera settings will break
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 60;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UVineComponent VineComp;
	UCameraUserComponent CameraUser;

	FVector LastRightVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		VineComp = UVineComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive() 
			&& VineComp.VineActiveType == EVineActiveType::Inactive
			&& !VineComp.VineActor.bHidden)
		{
			// Force the deactivation if the vine gets activated badly
			VineComp.VineActor.DeactivateVine();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(ActionNames::WeaponAim))
            return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DontDeactivate;
		
		if(VineComp.VineActiveType != EVineActiveType::Inactive)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);
		
		SetMutuallyExclusive(ActionNames::WeaponAim, true);
		SetMutuallyExclusive(CapabilityTags::CharacterFacing, true);
		
		VineComp.StartAiming();
		CameraUser.SetAiming(this);
		LastRightVector = Player.GetActorRightVector();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);

		SetMutuallyExclusive(ActionNames::WeaponAim, false);
		SetMutuallyExclusive(CapabilityTags::CharacterFacing, false);

		VineComp.StopAiming();
		VineComp.ClearVineHitResult();
		VineComp.bHasValidTarget = false;
		CameraUser.ClearAiming(this);
		VineComp.bCanActivateVine = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MoveComp.SetAnimationToBeRequested(n"VineMovement");

		// Since we are doing async traces, we need to wait for the tracing
		FVineHitResult CurrentVineHit;
		VineComp.bCanActivateVine = VineComp.GetVineImpact(CurrentVineHit);
		
		if(VineComp.VineActiveType == EVineActiveType::Inactive)
		{
			UVineImpactComponent TargetPoint; 
			FAutoAimLine AutoAimLine = GetAutoAimForTargetLine(Player, Player.ViewLocation, Player.ViewRotation.Vector(), 0.f, VineComp.MaximumDistance, false);
			if(AutoAimLine.AutoAimedAtActor != nullptr)
			{
				// Auto aim has heigher priority then activation point system
				auto ImpactComponent = UVineImpactComponent::Get(AutoAimLine.AutoAimedAtActor);
				if(ImpactComponent != nullptr && ImpactComponent.IsValidTarget())
				{
					TargetPoint = ImpactComponent;
				}
			}

			if(TargetPoint == nullptr)
			{
				UVineImpactComponent BestTargetPoint = Cast<UVineImpactComponent>(Player.GetTargetPoint(UVineImpactComponent::StaticClass()));
				// if(BestTargetPoint != CurrentVineHit.ImpactComponent)
				// 	TargetPoint = BestTargetPoint;
			}
				
			VineComp.UpdateVineTraceHitResult(TargetPoint, IsDebugActive());
					
			// We query using the new traces
			Player.UpdateActivationPointAndWidgets(UVineImpactComponent::StaticClass());
		}

		// Update face rotation
		VineComp.bHasValidTarget = CurrentVineHit.ImpactComponent != nullptr;
		if(VineComp.bHasValidTarget)
		{
			const FVector FaceDir = (CurrentVineHit.ImpactLocation - Player.GetActorLocation()).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			if(FaceDir.IsNearlyZero())
				MoveComp.SetTargetFacingRotation(Player.ViewRotation, 5.f);
			else
				MoveComp.SetTargetFacingDirection(FaceDir, 2.5f);
		}
		else
		{
			MoveComp.SetTargetFacingRotation(Player.ViewRotation, 10.f);
		}

		const FVector CurrentForward = Player.GetActorForwardVector();
		float MoveDir = CurrentForward.DotProduct(LastRightVector) / DeltaTime;
		MoveDir = FMath::Min(FMath::Abs(MoveDir), 1.f) * FMath::Sign(MoveDir);
		Player.SetAnimFloatParam(n"TurnSpeed", MoveDir);
		LastRightVector = Player.GetActorRightVector();
		//System::DrawDebugSphere(VineComp.GetTargetPoint(), 200, LineColor = FLinearColor::Red);
	}
}