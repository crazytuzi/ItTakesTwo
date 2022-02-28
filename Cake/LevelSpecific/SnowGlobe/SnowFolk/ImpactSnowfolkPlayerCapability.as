import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowfolkSplineFollower;

class UImpactSnowfolkPlayerCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	ASnowfolkSplineFollower Snowfolk;

	FVector Impulse;

	float HitTime;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
 		if(Snowfolk == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Snowfolk == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

 	//	if(Time::GetGameTimeSeconds() > HitTime)
	//		return EHazeNetworkDeactivation::DeactivateLocal;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) 
	{
	//	PrintScaled("Hit " + Player.Name, 1.f, FLinearColor::Green, 5.f); 			
	//	Player.PlaySlotAnimation(Animation = (Player.IsMay() ? SnowballFightComponent.MayHitAnimation : SnowballFightComponent.CodyHitAnimation));

		HitTime = Time::GetGameTimeSeconds() + 0.f;
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		FVector Normal = -(Player.GetActorLocation() - Snowfolk.GetActorLocation()).GetSafeNormal();

		FVector VelocityNormalCross = MoveComp.Velocity.CrossProduct(Normal).GetSafeNormal();
		FVector DeflectionVector = Normal.CrossProduct(VelocityNormalCross).GetSafeNormal();

		DeflectionVector = DeflectionVector * 2000.f + MoveComp.Velocity;
		DeflectionVector.Normalize();
		FVector NewVelocity = DeflectionVector * MoveComp.Velocity.Size();

	//	System::DrawDebugLine(Snowfolk.GetActorLocation(), Snowfolk.GetActorLocation() + VelocityNormalCross * 500.f, FLinearColor::Blue, 1.f, 40.f);
	//	System::DrawDebugLine(Snowfolk.GetActorLocation(), Snowfolk.GetActorLocation() + Normal * 500.f, FLinearColor::Red, 1.f, 40.f);
	//	System::DrawDebugLine(Snowfolk.GetActorLocation(), Snowfolk.GetActorLocation() + DeflectionVector * 500.f, FLinearColor::Green, 1.f, 40.f);
	//	System::DrawDebugLine(Snowfolk.GetActorLocation(), Snowfolk.GetActorLocation() + MoveComp.Velocity.GetSafeNormal() * 500.f, FLinearColor::Yellow, 1.f, 40.f);

		MoveComp.SetVelocity(NewVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Snowfolk = GetOverlappingSnowfolk();
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SnowfolkImpactFrameMove");

		FrameMove.OverrideStepDownHeight(0.f);
		FrameMove.ApplyActorVerticalVelocity();
		FrameMove.ApplyActorHorizontalVelocity();
		FrameMove.ApplyGravityAcceleration();
		FrameMove.ApplyTargetRotationDelta();

		MoveComp.Move(FrameMove);
	}

	ASnowfolkSplineFollower GetOverlappingSnowfolk()
	{
		TArray<AActor> OverlappingActors;

		Player.CapsuleComponent.GetOverlappingActors(OverlappingActors, ASnowfolkSplineFollower::StaticClass());

		if (OverlappingActors.Num() == 0)
			return nullptr;

		return Cast<ASnowfolkSplineFollower>(OverlappingActors[0]);
	}

};