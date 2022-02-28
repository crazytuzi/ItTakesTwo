import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UWallWalkingAnimalLaunchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SurfaceAlign");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	AWallWalkingAnimal TargetAnimal;
	UHazeCameraComponent StaticCamera;
	UNiagaraComponent CurrentWebBeam;

	const float StartDelay = 0.1f;
	const float ReachTargetTime = 0.6f;
	const float EndDelay = 0.f;

	float TimeLeftToStart = 0.f;
	float TimeLeftToReachTarget = 0.f;
	float TimeLeftToEnd = 0.f;

	FVector InitialLocation = FVector::ZeroVector;
	FQuat InitialRotation = FQuat::Identity;
	//FVector TargetLocation = FVector::ZeroVector;
	//FQuat TargetRotation = FQuat::Identity;

	FVector LastWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		TargetAnimal = Cast<AWallWalkingAnimal>(Owner);
		//TargetAnimal.WebBeam.SetHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{   
		if(!TargetAnimal.bLaunching)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TargetAnimal.bLaunching)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TimeLeftToEnd <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"ImpactComponent", TargetAnimal.CurrentTransitionTarget.Component);
		
		FVector RelativeLocation = TargetAnimal.CurrentTransitionTarget.ImpactPoint;
		RelativeLocation = TargetAnimal.CurrentTransitionTarget.Component.GetWorldTransform().InverseTransformPositionNoScale(RelativeLocation);
		ActivationParams.AddVector(n"ImpactLocation", RelativeLocation);
		
		FVector RelativeNormal = TargetAnimal.CurrentTransitionTarget.ImpactNormal;
		RelativeNormal = TargetAnimal.CurrentTransitionTarget.Component.GetWorldTransform().InverseTransformVectorNoScale(RelativeNormal);
		ActivationParams.AddVector(n"ImpactNormal", RelativeNormal);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"SurfaceAlign", true);
		
		TargetAnimal.SetActorEnableCollision(false);
		TargetAnimal.LaunchLeftAlpha = 1.f;
		TargetAnimal.Player.BlockCapabilities(n"SpiderTutorial", this);

		// We setup the correct impact location relative to the object on the remote side
		if(!HasControl())
		{
			UPrimitiveComponent ImpactComponent = Cast<UPrimitiveComponent>(ActivationParams.GetObject(n"ImpactComponent"));
			
			FVector ImpactLocation = ActivationParams.GetVector(n"ImpactLocation");
			ImpactLocation = ImpactComponent.GetWorldTransform().TransformPositionNoScale(ImpactLocation);
			
			FVector ImpactNormal = ActivationParams.GetVector(n"ImpactNormal");
			ImpactNormal = ImpactComponent.GetWorldTransform().TransformVectorNoScale(ImpactNormal);

			FHitResult ReplicatedResult;	
			ReplicatedResult = FHitResult(ImpactComponent.GetOwner(), ImpactComponent, ImpactLocation, ImpactNormal);
			TargetAnimal.LaunchToCeiling(ReplicatedResult);
		}

		TargetAnimal.TransitionPoint.AttachToComponent(TargetAnimal.CurrentTransitionTarget.Component);

		//TargetLocation = TargetAnimal.CurrentTransitionTarget.ImpactPoint;
		FTransform TargetTransform(TargetAnimal.CurrentTransitionTarget.ImpactPoint);
	
		// Create the rotation from the actors forward and the impact normal
		FVector WantedForward = TargetAnimal.GetActorForwardVector().ConstrainToPlane(TargetAnimal.CurrentTransitionTarget.ImpactNormal).GetSafeNormal();
		TargetTransform.SetRotation(Math::MakeQuatFromZX(TargetAnimal.CurrentTransitionTarget.ImpactNormal, WantedForward));

		TargetAnimal.TransitionPoint.SetWorldTransform(TargetTransform);

		// Todo change this to the new mesh
		if(TargetAnimal.WebBeamImpactType != nullptr)
		{
			auto SpawnEffect = Niagara::SpawnSystemAttached(
				TargetAnimal.WebBeamImpactType,
				TargetAnimal.CurrentTransitionTarget.Component,
				NAME_None,
				TargetTransform.Location, 
				TargetTransform.Rotator(),
				EAttachLocation::KeepWorldPosition,
				true);
		}

		// Timers to make the launch move
		TimeLeftToStart = StartDelay;
		TimeLeftToReachTarget = ReachTargetTime;
		TimeLeftToEnd = FMath::Max(EndDelay, SMALL_NUMBER);

		InitialLocation = TargetAnimal.GetActorLocation();
		InitialRotation = TargetAnimal.GetActorQuat();

		if(TargetAnimal.WebBeamType != nullptr)
		{
			CurrentWebBeam = Niagara::SpawnSystemAttached(
				TargetAnimal.WebBeamType, 
				TargetAnimal.CurrentTransitionTarget.Component,
				NAME_None,
				TargetAnimal.GetActorCenterLocation(), 
				TargetAnimal.GetActorRotation(), 
				EAttachLocation::SnapToTarget,
				bAutoDestroy=false);

			CurrentWebBeam.SetNiagaraVariableVec3("BeamStart", TargetAnimal.GetActorCenterLocation());
			CurrentWebBeam.SetNiagaraVariableVec3("BeamEnd", TargetTransform.Location);
		}	

		TargetAnimal.MeshOffsetComponent.FreezeAndResetWithTime(0.2f);

		TargetAnimal.Player.PlayForceFeedback(TargetAnimal.LaunchForceFeedback, false, true, n"SpiderLaunch");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"SurfaceAlign", false);
		TargetAnimal.SetActorEnableCollision(true);	
		TargetAnimal.FinishTransition();
		TargetAnimal.Player.UnblockCapabilities(n"SpiderTutorial", this);
		if(CurrentWebBeam != nullptr)
		{
			CurrentWebBeam.DestroyComponent(this);
			CurrentWebBeam = nullptr;
		}

		TargetAnimal.TransitionPoint.AttachToComponent(TargetAnimal.RootComponent);
		TargetAnimal.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
		TargetAnimal.LaunchCooldown = Time::GameTimeSeconds + 0.5f;

		TargetAnimal.Player.PlayForceFeedback(TargetAnimal.LandForceFeedback, false, true, n"SpiderLand");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"LaunchWallWalkingAnimal");
		MoveData.OverrideStepUpHeight(0.f);
		//MoveData.OverrideGroundedState(EHazeGroundedState::Grounded);
		TargetAnimal.Mesh.SetWorldRotation(InitialRotation);
		if(CurrentWebBeam != nullptr)
		{
			CurrentWebBeam.SetNiagaraVariableVec3("BeamEnd", TargetAnimal.TransitionPoint.GetWorldLocation());
		}
				
		// Lift the animal up in the air so we can rotate it
		if(TimeLeftToStart > 0)
		{
			TimeLeftToStart -= DeltaTime;
			if(TimeLeftToStart <= 0)
			{
				TargetAnimal.TriggerLaunchToCeiling();
			}

			MoveData.OverrideStepDownHeight(1.f);
			MoveCharacter(MoveData, n"Movement");
		}
		// Rotate and move toward the impact location
		else if(TimeLeftToReachTarget > 0)
		{
			TimeLeftToReachTarget = FMath::Max(TimeLeftToReachTarget - DeltaTime, 0.f); 
			TargetAnimal.LaunchLeftAlpha = (TimeLeftToReachTarget / ReachTargetTime);
			const float LerpAlpha = 1 - TargetAnimal.LaunchLeftAlpha;

			const FTransform TargetTransform = TargetAnimal.TransitionPoint.GetWorldTransform();

			const FQuat WantedRotation = FQuat::Slerp(InitialRotation, TargetTransform.Rotation, LerpAlpha);
			FVector WantedLocation = FMath::Lerp(InitialLocation, TargetTransform.Location, LerpAlpha);
			WantedLocation += TargetAnimal.CurrentTransitionTarget.ImpactNormal * (TargetAnimal.GetCollisionSize().Y * 0.5f);

			const FVector NewWorldUp = WantedRotation.GetUpVector();
			TargetAnimal.GroundTraces.SetTracesNormal(NewWorldUp);
			TargetAnimal.ChangeActorWorldUp(NewWorldUp);
			MoveData.SetRotation(WantedRotation);
			MoveData.ApplyDeltaWithCustomVelocity(WantedLocation - TargetAnimal.GetActorLocation(), FVector::ZeroVector);
				
			if(TimeLeftToReachTarget <= 0)
			{
				TargetAnimal.SetActorEnableCollision(true);
				TargetAnimal.TriggerLaunchToCeilingEnding();
				MoveData.OverrideStepDownHeight(200.f);
			
				MoveCharacter(MoveData, n"Movement");
			}	
			else
			{		
				MoveData.OverrideStepDownHeight(1.f);
				MoveCharacter(MoveData, n"Movement");
			}
		}
		// Delay before we end
		else if(TimeLeftToEnd > 0)
		{
			TimeLeftToEnd = FMath::Max(TimeLeftToEnd - DeltaTime, 0.f);
			MoveCharacter(MoveData, n"Movement");
		}

		TargetAnimal.CrumbComp.LeaveMovementCrumb();

	#if EDITOR
		if(IsDebugActive())
		{
			FVector DebugLog = TargetAnimal.GetActorLocation();
			System::DrawDebugArrow(DebugLog, DebugLog + (TargetAnimal.GetMovementWorldUp() * 1000.f), LineColor = FLinearColor::Red, Thickness = 5);
			
			const FTransform TargetTransform = TargetAnimal.TransitionPoint.GetWorldTransform();
			System::DrawDebugArrow(DebugLog, DebugLog + (TargetTransform.Rotation.GetUpVector() * 600.f), LineColor = FLinearColor::Blue, Thickness = 10);
		}
	#endif

		if(!HasControl())
		{
			FHazeActorReplicationFinalized ReplicatedMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicatedMovement);
		}
	
		if(CurrentWebBeam != nullptr)
			CurrentWebBeam.SetNiagaraVariableVec3("BeamStart", TargetAnimal.GetActorLocation());
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString FinalText;

		FinalText += "TransitionType:\n" + TargetAnimal.GetActiveTransitionType() + "\n";
		

		if(TimeLeftToStart > 0)
		{
			FinalText += "Time left START: " + TimeLeftToStart + "\n";
		}
		else if(TimeLeftToReachTarget > 0)
		{
			FinalText += "Time left TARGET: " + TimeLeftToReachTarget + "\n";
		}

		return FinalText;
	}
}