import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;

// Class that predicts the characters future location in the crumb component
class USneakyBushPlayerWantingToHideLocationCalculator : UHazeReplicationLocationCalculator
{
	FHazeAcceleratedVector TargetLocation;
	FVector WantedTargetLocation = FVector::ZeroVector;
	FVector LastReceivedPlayerLocation = FVector::ZeroVector;

	UControllablePlantsComponent PlantsComponent;
	AHazePlayerCharacter PlayerOwner = nullptr;
	ASneakyBush Bush;

	const float ValidDistance = 800.f;

	FHazeAcceleratedRotator CrumbRotation;
	FRotator TargetRotation;
	bool bUsingPlayerLocation = true;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent InRelativeComponent)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlantsComponent = UControllablePlantsComponent::Get(InRelativeComponent.Owner);
		Bush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);
		Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FHazeActorReplicationFinalized CurrentParams)
	{
		Reset();
	}

	private void Reset()
	{
		LastReceivedPlayerLocation = WantedTargetLocation = PlayerOwner.GetActorLocation();
		TargetRotation = PlayerOwner.GetActorRotation();
		TargetLocation.SnapTo(LastReceivedPlayerLocation);
		CrumbRotation.SnapTo(TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		OutTargetParams.CustomLocation = OutTargetParams.Location - Bush.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{	
		WantedTargetLocation = Bush.GetActorLocation();
		WantedTargetLocation += TargetParams.CustomLocation;
		LastReceivedPlayerLocation = TargetParams.Location;

		const float HeightOffset = PlayerOwner.GetCollisionSize().Y;

		FHazeTraceParams TraceParams;
		TraceParams.InitWithMovementComponent(PlayerOwner.MovementComponent);
		TraceParams.SetToLineTrace();
		TraceParams.From = LastReceivedPlayerLocation;
		TraceParams.From.Z += HeightOffset;
		TraceParams.To = WantedTargetLocation;
		TraceParams.To.Z += HeightOffset;

		//FVector FinalTraceResult = WantedTargetLocation;
		FHazeHitResult ForwardHit;
		if(TraceParams.Trace(ForwardHit))
		{
			WantedTargetLocation = (TraceParams.From - TraceParams.To).GetSafeNormal() * (ForwardHit.Distance - PlayerOwner.GetCollisionSize().X);
			WantedTargetLocation.Z -= HeightOffset;
		}

		TraceParams.From = WantedTargetLocation;
		TraceParams.To = WantedTargetLocation;
		TraceParams.From.Z += HeightOffset * 2;
		TraceParams.To.Z -= 25.f;
		FHazeHitResult DownHit;
		if(TraceParams.Trace(DownHit))
			WantedTargetLocation = DownHit.ImpactPoint;

		if(bUsingPlayerLocation)
		{
			if(LastReceivedPlayerLocation.DistSquared(PlayerOwner.GetActorLocation()) < FMath::Square(50))
			{
				TargetRotation = TargetParams.Rotation;
			}
			else
			{
				const FVector DirToTaget = (LastReceivedPlayerLocation - PlayerOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				TargetRotation = DirToTaget.ToOrientationRotator();
				TargetParams.Velocity = DirToTaget * TargetParams.Velocity.Size();
				TargetParams.Input = TargetParams.Velocity.GetSafeNormal();
			}
		}
		else
		{
			const FVector DirToTaget = (WantedTargetLocation - PlayerOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			if(!DirToTaget.IsNearlyZero())
			{
				TargetRotation = DirToTaget.ToOrientationRotator();
				TargetParams.Velocity = DirToTaget * TargetParams.Velocity.Size();
				TargetParams.Input = TargetParams.Velocity.GetSafeNormal();
			}
			else 
			{
				const FVector HorizontalVelDir = PlayerOwner.ActualVelocity.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				if(!HorizontalVelDir.IsNearlyZero())
				{
					TargetRotation = HorizontalVelDir.ToOrientationRotator();
					TargetParams.Velocity = HorizontalVelDir * TargetParams.Velocity.Size();
					TargetParams.Input = TargetParams.Velocity.GetSafeNormal();
				}		
			}
		}

		TargetParams.Rotation = CrumbRotation.Value;
		TargetParams.Location = TargetLocation.Value;
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		//TargetParams.SetInput(TargetParams.Velocity.GetSafeNormal());
		//TargetParams.SetRotation(Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
		const float LerpSpeed = CurrentParams.GetVelocity().Size();
		const FVector BushVelocityDir = Bush.MovementComp.GetVelocity().GetSafeNormal();
		const FVector PlayerVelocityDir = PlayerOwner.MovementComponent.GetVelocity().GetSafeNormal();
		const float Dist = Bush.GetActorLocation().Dist2D(WantedTargetLocation);

		if(Bush.GetActorLocation().DistSquared2D(WantedTargetLocation) > FMath::Square(ValidDistance)
			|| CurrentParams.ReplicatedInput.IsNearlyZero(0.1f)
			|| PlayerVelocityDir.IsNearlyZero(0.1f) 
			|| BushVelocityDir.IsNearlyZero(0.1f))
		{
			FVector NewPostion;
			if(Bush.GetActorLocation().DistSquared2D(WantedTargetLocation) < FMath::Square(200.f))
				NewPostion = FMath::VInterpConstantTo(TargetLocation.Value, LastReceivedPlayerLocation, DeltaTime, PlayerOwner.MovementComponent.MoveSpeed * 1.1f);
			else
				NewPostion = FMath::VInterpTo(TargetLocation.Value, LastReceivedPlayerLocation, DeltaTime, 6.f);
			TargetLocation.SnapTo(NewPostion);
			bUsingPlayerLocation = true;
		}
		else
		{
			const float CorrectionAlpha = FMath::Lerp(0.2f, 1.f, Math::GetNormalizedDotProduct(PlayerVelocityDir, BushVelocityDir));
			const float ValidSpeedMultiplier = FMath::Lerp(0.5f, 1.5f, CorrectionAlpha);
			const FVector LerpToLocation = FMath::Lerp(LastReceivedPlayerLocation, WantedTargetLocation, CorrectionAlpha);
			TargetLocation.AccelerateTo(LerpToLocation, 1.f, DeltaTime);
			bUsingPlayerLocation = CorrectionAlpha < 0.25f;
		}

		CrumbRotation.AccelerateTo(TargetRotation, 0.5f, DeltaTime);
	
		// System::DrawDebugSphere(WantedTargetLocation, LineColor = FLinearColor::Red);
		// System::DrawDebugSphere(TargetLocation.Value, LineColor = FLinearColor::Blue);
		// System::DrawDebugSphere(LastReceivedPlayerLocation, LineColor = FLinearColor::Green);
	}
}

class USneakyBushPlayerWantingToHideCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;
	UHazeCrumbComponent CrumbComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
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
		CrumbComponent.MakeCrumbsUseCustomWorldCalculator(USneakyBushPlayerWantingToHideLocationCalculator::StaticClass(), this, Game::GetCody().RootComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComponent.RemoveCustomWorldCalculator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			

	}
}
