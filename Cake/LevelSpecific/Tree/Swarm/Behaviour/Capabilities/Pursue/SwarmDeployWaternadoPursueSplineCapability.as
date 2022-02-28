

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Waternado.WaternadoSpawnerComponent;

UCLASS(abstract)
class USwarmDeployWaternadoPursueSplineCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::PursueSpline;

	// whether the VFX and scaling is handled in sequncer or not
	bool bHandledBySquencer = true;

	UPROPERTY(Category = "Animation")
	USwarmAnimationSettingsBaseDataAsset PursueSplineAnim;

	UPROPERTY(Category = "Animation")
	USwarmAnimationSettingsBaseDataAsset StartTornadoAnim;

	UPROPERTY(Category = "Animation")
	USwarmAnimationSettingsBaseDataAsset FastTornadoAnim;

	UPROPERTY(Category = "Animation")
	USwarmAnimationSettingsBaseDataAsset VeryFastTornadoAnim;

	bool bSpringToWaterSurface = false;
	bool bCOMReachedEnd = false;
	float TimeStampActorReachedEnd = 0.f;

	FHazeAcceleratedVector SwarmScale;
	// FVector DesiredSwarmScale = FVector(0.5f, 0.5f, 2.5f);
	//FVector DesiredSwarmScale = FVector(1.f, 1.f, 2.f);
	// FVector DesiredSwarmScale = FVector(3.f, 3.f, 5.f);
	FVector DesiredSwarmScale = FVector(1.f, 1.f, 3.f);

	AWaternado Nado = nullptr;
	FVector DesiredScale = FVector::ZeroVector;
	FHazeAcceleratedFloat ScaleX;
	FHazeAcceleratedFloat ScaleY;
	FHazeAcceleratedFloat ScaleZ;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
 			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation( PursueSplineAnim, this);

		BehaviourComp.NotifyStateChanged();
		MoveComp.InitMoveAlongSpline();

		bSpringToWaterSurface = true;

		//SwarmActor.BlockCapabilities(n"SwarmMovement", this);
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		if(Nado != nullptr && !bHandledBySquencer)
			Nado.SetActorScale3D(DesiredScale);
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float Dt)
	{
		if(!bHandledBySquencer)
		{
			UpdateWaternadoScaling(Dt);
			UpdateSwarmScaling(Dt);
		}

		UpdateSwarmMovement(Dt);

		BehaviourComp.FinalizeBehaviour();
	}

	void UpdateWaternadoScaling(const float Dt)
	{
		if(Nado == nullptr)
			return;

		ScaleX.AccelerateTo(DesiredScale.X, 12.f, Dt);
		ScaleY.AccelerateTo(DesiredScale.Y, 12.f, Dt);
		ScaleZ.AccelerateTo(DesiredScale.Z, 16.f, Dt);

		const FVector CurrentScale = FVector(
			ScaleX.Value,
			ScaleY.Value,
			ScaleZ.Value
		);

		Nado.SetActorScale3D(CurrentScale);
	}

	void UpdateSwarmScaling(const float Dt)
	{
		// don't do any scaling if we don't have the nado yet
		if(Nado == nullptr)
			return;

		SwarmScale.AccelerateTo(DesiredSwarmScale, 9.f, Dt);
		SwarmActor.SetActorScale3D(SwarmScale.Value);
	}

	void UpdateSwarmMovement(const float Dt)
	{
		// Attach to the nado translation wise (we want to ignore scaling)
		if(Nado != nullptr)
			SwarmActor.SetActorLocation(Nado.GetActorLocation());

		if(!bCOMReachedEnd)
		{
			const bool bActorReachedEnd = MoveComp.MoveAlongSpline(8000.f, Dt);

			if(bActorReachedEnd)
			{
				if(TimeStampActorReachedEnd == 0.f)
				{
					if(HasControl())
					{
						NetHandleActorReachedSplineEnd();
					}
				}
				
				const float TimeSinceActorReachedEnd = Time::GetGameTimeSince(TimeStampActorReachedEnd);
				const FVector ToCOM = SwarmActor.GetSwarmCenterOfParticles() - SwarmActor.GetActorLocation();
				const float DistToCOM = ToCOM.Size();

				if(DistToCOM < 500.f || TimeSinceActorReachedEnd > 2.f)
				{
					if(HasControl())
					{
						NetHandleCenterReachedSplineEnd();
					}
				}
			}
		}
		else if(bSpringToWaterSurface)
		{
			SpringToWaterSurface(Dt);
		}
	}

	void SpringToWaterSurface(const float Dt)
	{
		UWaternadoSpawnerComponent NadoSpawnerComp = UWaternadoSpawnerComponent::Get(SwarmActor);
		if(NadoSpawnerComp.WaterSurfaceActor == nullptr)
			return;
			
		float SurfaceHeight = SwarmActor.GetActorLocation().Z; 
		if(NadoSpawnerComp.WaterSurfaceActor.GetHeightAtLocation(SwarmActor.GetActorLocation(), SurfaceHeight))
		{
			FVector TargetPos = SwarmActor.GetActorLocation();
			TargetPos.Z = SurfaceHeight;
			MoveComp.SpringToTargetWithTime(TargetPos, 4.f, Dt);
			SwarmActor.SetActorLocation(MoveComp.DesiredSwarmActorTransform.GetLocation());
		}
	}

    UFUNCTION(NetFunction)
	void NetHandleActorReachedSplineEnd()
	{
		TimeStampActorReachedEnd = Time::GetGameTimeSeconds();

		SwarmActor.BlockCapabilities(n"SwarmMovement", this);
		FQuat Q = SwarmActor.GetActorQuat();
		FQuat S, T;
		Q.ToSwingTwist( FVector::UpVector, S, T);
		SwarmActor.SetActorRotation(T);
	}

    UFUNCTION(NetFunction)
	void NetHandleCenterReachedSplineEnd()
	{
		const float BlendInTime = 4.f;
		SwarmActor.PlaySwarmAnimation( StartTornadoAnim, this, BlendInTime);
		System::SetTimer( this, n"TimerOne", BlendInTime, bLooping=false);

		bCOMReachedEnd = true;
		SwarmActor.OnReachedEndOfSpline.Broadcast(SwarmActor);
	}

    UFUNCTION()
    void TimerOne()
    {
		const float BlendInTime = 0.1f;
		SwarmActor.PlaySwarmAnimation( FastTornadoAnim, this, BlendInTime);
		System::SetTimer(
			this,
			n"TimerTwo", 
			BlendInTime,
			bLooping=false
		);
		bSpringToWaterSurface = false;
    }

    UFUNCTION()
    void TimerTwo()
    {
		SwarmActor.PlaySwarmAnimation( VeryFastTornadoAnim, this, 2.f);

		UWaternadoSpawnerComponent NadoSpawnerComp = UWaternadoSpawnerComponent::Get(SwarmActor);
		Nado = NadoSpawnerComp.SpawnWaternado();

		if(!bHandledBySquencer)
		{
			Nado.SpawnSplash1.Activate();

			DesiredScale = Nado.GetActorScale3D();
			float InitScale = 0.01f;
			ScaleX.SnapTo(DesiredScale.X * 0.8f);
			ScaleY.SnapTo(DesiredScale.Y * 0.8f);
			ScaleZ.SnapTo(InitScale);

			Nado.SetActorScale3D(FVector(InitScale));
			SwarmScale.SnapTo(SwarmActor.GetActorScale3D());
		}
		else
		{
			NadoSpawnerComp.PlayCutsceneEvent.Broadcast(SwarmActor, Nado);
		}

		// Don't attach because the nado might scale 
		//SwarmActor.AttachToActor(Nado);

        System::SetTimer(this, n"DeactivateSwarm", 12.f, bLooping=false);
    }

    UFUNCTION()
    void DeactivateSwarm()
    {
		// PrintToScreen("Hide him!!!", Duration = 4.f);

		// SwarmActor.DisableActor(this);
		// // SwarmActor.DestroyActor();

		// if(!bHandledBySquencer)
		// 	Nado.SpawnSplash1.Deactivate();
    }

}











