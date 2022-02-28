import Vino.Interactions.DoubleInteractionJumpTo;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineFollowerComponent;
import Vino.Camera.Components.FocusTrackerComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Tree.Boat.TreeWaterLarva;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingObstacle;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingCheckpoint;

import void StartRidingBeetle(AHazePlayerCharacter Player, ATreeBeetleRidingBeetle Beetle) from "Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent";
import void StopRidingBeetle(AHazePlayerCharacter Player) from "Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent";

event void FTreeBeetleRidingTakeDamage(float Amount);
event void FTreeBeetleRidingnBeetleStart();
event void FTreeBeetleRidingnBeetleDie();

enum ETreeBeetleDamageType
{
	Collision,
	LarvaBomb
}

class ATreeBeetleRidingBeetle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UFocusTrackerComponent FocusTrackerComponent;
	default FocusTrackerComponent.UserFocus.Weight = 0.f;

	UPROPERTY(DefaultComponent, Attach = FocusTrackerComponent)
	UHazeCameraComponent Camera;

//	UPROPERTY(DefaultComponent, Attach = KeepInViewComponent)
//	UHazeCameraComponent DeathCamera;

	UPROPERTY()
	ADoubleInteractionJumpTo DoubleInteractionActor;

//	UPROPERTY(DefaultComponent)
//	UInteractionComponent InteractionComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent BeetleMovementRoot;

	UPROPERTY(DefaultComponent, Attach = BeetleMovementRoot)
	USphereComponent OverlapSphere;

	UPROPERTY(DefaultComponent, Attach = BeetleMovementRoot)
	UHazeSkeletalMeshComponentBase BeetleSkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = BeetleSkeletalMesh, AttachSocket = "Neck")
//	UPROPERTY(DefaultComponent, Attach = BeetleSkeletalMesh)
	USceneComponent MayPosition;

	UPROPERTY(DefaultComponent, Attach = BeetleSkeletalMesh, AttachSocket = "Neck")
//	UPROPERTY(DefaultComponent, Attach = BeetleSkeletalMesh)
	USceneComponent CodyPosition;

	UPROPERTY(DefaultComponent)
	UConnectedHeightSplineFollowerComponent SplineFollowerComponent;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent ReplicatedSplineFollowComponent;

	UPROPERTY()
	UHazeCapabilitySheet TreeBeetleRidingCapabilitySheet;

	UPROPERTY()
	FTreeBeetleRidingnBeetleStart OnBeetleRideStart;

	UPROPERTY()
	FTreeBeetleRidingTakeDamage OnTakeDamage;

	UPROPERTY()
	FTreeBeetleRidingnBeetleDie OnBeetleDie;

	UPROPERTY()
	bool bCanBeControlled = true;

	UPROPERTY()
	bool bIsMayOn;
	
	UPROPERTY()
	bool bIsCodyOn;

	UPROPERTY(Category = "Beetle Settings")
	bool bForcePlayerRide;

	UPROPERTY(Category = "Beetle Settings")
	float SideSpeed = 6000.f;

	UPROPERTY(Category = "Beetle Settings")
	FVector ForwardForce = FVector(3000.f, 0.f, 0.f);

	FVector TurnForce;

	UPROPERTY(Category = "Beetle Settings")
	FVector DragVector = FVector(1.f, 5.f, 1.f);

	UPROPERTY(Category = "Beetle Settings")
	FVector Velocity;

	UPROPERTY(Category = "Beetle Settings")
	FVector Gravity = FVector(0.f, 0.f, -980.f);

	UPROPERTY(Category = "Beetle Settings")
	float JumpImpulse = 2000.f;

	UPROPERTY(Category = "Beetle Settings")
	float JumpHeightMargin = 400.f;

	UPROPERTY(Category = "Beetle Settings")
	float CoyoteTime = 0.25f;
	float CoyoteTimer = 0.f;

	UPROPERTY(Category = "Beetle Settings")
	float MaxHealth = 12.f;
	float Health = 0.f;

	UPROPERTY(Category = "Beetle VFX")
	UNiagaraSystem VFX_BeetleRun;

	UPROPERTY(Category = "Beetle VFX")
	UNiagaraSystem VFX_BeetleCrash;

	UPROPERTY(Category = "Beetle VFX")
	UNiagaraSystem VFX_BeetleJump;

	UPROPERTY(Category = "Beetle VFX")
	UNiagaraSystem VFX_BeetleLand;

	UPROPERTY()
	bool bIsRunning;

	UPROPERTY()
	bool bIsJumping;

	UPROPERTY()
	bool bIsDashing;

	UPROPERTY()
	bool bIsDead;

	UPROPERTY()
	bool bIsCrashingInAir;

	UPROPERTY()
	bool bIsCrashingOnGround;

	UPROPERTY()
	bool bIsFalling;

	float DashTimer = 0.f;
	float DashCooldown = 1.f;

	UPROPERTY(Category = "Beetle Settings")
	bool bStartDisabled;

	FVector Location;
	FQuat Rotation;

	UPROPERTY(Category = "Beetle Settings")
	FVector CameraTargetLerpSpeed = FVector(1.f, 1.f, 1.f);

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect TakeDamageForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> TakeDamageCameraShake;

	FHazeCameraBlendSettings CameraBlendSettings;
	EHazeViewPointBlendSpeed ViewPointBlendSpeed = EHazeViewPointBlendSpeed::Normal;
	FTransform PreviousCameraTransform;
	FTransform InitialRelativeCameraTransform;

//	UPROPERTY(DefaultComponent)
//	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Health = MaxHealth;

		// Cody Control in Network
		Network::SetActorControlSide(this, Game::GetCody());

		if (bStartDisabled)
			DisableActor(this);

		Capability::AddPlayerCapabilitySheetRequest(TreeBeetleRidingCapabilitySheet);

		if (DoubleInteractionActor != nullptr)
		{
			DoubleInteractionActor.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
			DoubleInteractionActor.LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
			DoubleInteractionActor.RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);

//			DoubleInteractionActor.LeftInteraction.AttachToComponent(BeetleSkeletalMesh, n"Neck", EAttachmentRule::SnapToTarget);
//			DoubleInteractionActor.RightInteraction.AttachToComponent(BeetleSkeletalMesh, n"Neck", EAttachmentRule::SnapToTarget);

			DoubleInteractionActor.LeftInteraction.AttachToComponent(MayPosition, NAME_None, EAttachmentRule::SnapToTarget);
			DoubleInteractionActor.RightInteraction.AttachToComponent(CodyPosition, NAME_None, EAttachmentRule::SnapToTarget);

			DoubleInteractionActor.LeftInteraction.OnActivated.AddUFunction(this, n"OnInteractionActivated");
			DoubleInteractionActor.RightInteraction.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		
			DoubleInteractionActor.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnInteractionCanceled");
		}

//		InteractionComponent.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		SplineFollowerComponent.OnSplineTransition.AddUFunction(this, n"OnSplineTransition");
		SplineFollowerComponent.OnFootPrintOverlap.AddUFunction(this, n"OnFootPrintOverlap");
		SplineFollowerComponent.OnGrounded.AddUFunction(this, n"OnGrounded");
		OverlapSphere.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapSphereBeginOverlap");

		// HazeSplineFollowComponent
		SplineFollowerComponent.SetSplineActorSpline();
		ReplicatedSplineFollowComponent.ActivateSplineMovement(SplineFollowerComponent.Spline, SplineFollowerComponent.bForwardDirection);
		ReplicatedSplineFollowComponent.IncludeSplineInActorReplication(this);

		// Force Players to start riding on BeginPlay
		if (bForcePlayerRide)
			StartBeetleRide();

		Location = ActorLocation;
		Rotation = ActorQuat;

		InitialRelativeCameraTransform = CameraRoot.RelativeTransform;

		AddCapability(n"FullscreenSharedHealthAudioCapability");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(TreeBeetleRidingCapabilitySheet);

		// HazeSplineFollowComponent
		ReplicatedSplineFollowComponent.RemoveSplineFromActorReplication(this);
		ReplicatedSplineFollowComponent.DeactivateSplineMovement();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
//		if (!bIsRunning)
//			return;

		// CoyoteTime
		if (CoyoteTimer > 0.f)
		{
			PrintScaled("CoyoteTime", 0.f, FLinearColor::Green, 2.f);
			CoyoteTimer -= DeltaTime;
		}

		// Dash Timer
		if (DashTimer > 0.f)
			DashTimer -= DeltaTime;
		else
			bIsDashing = false;

//		FVector Location;
//		FQuat Rotation;

		if (bIsRunning && !bIsDead)
			MoveOnSpline(DeltaTime);

		if (bIsFalling)
			FallingMovement(DeltaTime);

		// Location and rotation Lerp for smoothing jitter !!! TESTING !!!
		if (!bIsFalling)
		{
			Location = FMath::VLerp(ActorLocation, Location, FVector(8.f) * DeltaTime);
			Rotation = FQuat::Slerp(ActorQuat, Rotation, DeltaTime * 8.f);
		}

		if (HasControl())
		{
			SetActorLocationAndRotation(Location, Rotation);
//			UpdateCamera(DeltaTime);

			FHazeSplineSystemPosition SplinePosition;
			SplinePosition.FromData(SplineFollowerComponent.Spline, SplineFollowerComponent.DistanceOnSpline, SplineFollowerComponent.bForwardDirection);

			if (SplinePosition.Spline != ReplicatedSplineFollowComponent.GetPosition().Spline)
				ReplicatedSplineFollowComponent.ActivateSplineMovement(SplinePosition);
			else 
				ReplicatedSplineFollowComponent.UpdateSplineMovementFromPosition(SplinePosition, EHazeSplineMovementPolarity::Positive);

//			CrumbComponent.SetCustomCrumbVector(CameraRoot.WorldLocation);
//			CrumbComponent.SetCustomCrumbRotation(CameraRoot.WorldRotation);
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			CrumbComponent.GetCurrentReplicatedData(CrumbData);

			ReplicatedSplineFollowComponent.UpdateReplicatedSplineMovement(CrumbData);

			FHazeSplineSystemPosition ReplicatedSplinePosition = ReplicatedSplineFollowComponent.GetPosition();
			
			SplineFollowerComponent.Spline = Cast<UConnectedHeightSplineComponent>(ReplicatedSplinePosition.Spline);
			SplineFollowerComponent.DistanceOnSpline = ReplicatedSplinePosition.DistanceAlongSpline;

			FVector Offset = SplineFollowerComponent.GetSplineTransform().InverseTransformPositionNoScale(CrumbData.Location);
			SplineFollowerComponent.Offset = Offset.Y;
			SplineFollowerComponent.Height = Offset.Z;
			SplineFollowerComponent.Update(DeltaTime);

			// Debug
//			System::DrawDebugSphere(SplineFollowerComponent.Transform.Location, 500.f, 12, FLinearColor::Green, 0.f, 5.f);
//			System::DrawDebugLine(CrumbData.Location + (ActorUpVector * 500.f), SplineFollowerComponent.Transform.Location, FLinearColor::Green, 0.f , 10.f);

			SetActorLocationAndRotation(CrumbData.Location, CrumbData.Rotation);
//			CameraRoot.SetWorldLocationAndRotation(CrumbData.CustomCrumbVector, CrumbData.CustomCrumbRotator);
		}

		if (bIsRunning)
			UpdateCamera(DeltaTime);

//		PrintToScreen("Height: " + SplineFollowerComponent.Height);

//		System::DrawDebugSphere(ReplicatedSplineFollowComponent.GetPosition().WorldLocation, 600.f, 12, FLinearColor::LucBlue, 0.f, 5.f);
//		System::DrawDebugSphere(SplineFollowerComponent.Transform.Location, 500.f, 12, FLinearColor::Green, 0.f, 5.f);
//		System::DrawDebugLine(ActorLocation + (ActorUpVector * 500.f), SplineFollowerComponent.Transform.Location, FLinearColor::Green, 0.f , 10.f);

	}

	void MoveOnSpline(float DeltaTime)
	{
		FVector Acceleration = ForwardForce * SplineFollowerComponent.Transform.Scale3D.Z
							 + TurnForce
							 + Gravity * 6.f
							 - Velocity * DragVector;

		Velocity += Acceleration * DeltaTime;

		// Remote side updates inside tick function
		if (HasControl())
		{
			SplineFollowerComponent.AddMovementVector(Velocity * DeltaTime);
		}

		if (bIsDead)
			return;

		if (SplineFollowerComponent.bIsGrounded)
			Velocity.Z = 0.f;

		Location = SplineFollowerComponent.Transform.Location;
		Rotation = SplineFollowerComponent.Transform.Rotation;
	}

	void FallingMovement(float DeltaTime)
	{
		FVector Acceleration = Gravity * 6.f
							 - Velocity * 1.f;

		Velocity += Acceleration * DeltaTime;

		Location = ActorLocation + Velocity * DeltaTime;
		Rotation = FRotator::MakeFromX(Velocity.GetSafeNormal()).Quaternion(); // Fix correct rotation?
	}


	UFUNCTION()
	void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(Camera, CameraBlend::Normal(1.f), this, EHazeCameraPriority::Script);
	}

	UFUNCTION()
	void OnInteractionReady(AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(Camera, CameraBlend::Normal(1.f), this, EHazeCameraPriority::Script);
	}

	UFUNCTION()
	void OnInteractionCanceled(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		Player.DeactivateCameraByInstigator(this);
	}

	UFUNCTION()
	void OnDoubleInteractionCompleted()
	{
		PrintScaled("Double Interaction Completed!", 1.f, FLinearColor::Green, 2.f);	

		if (DoubleInteractionActor != nullptr)
			DoubleInteractionActor.Disable(NAME_None);

		StartBeetleRide();
	}

	UFUNCTION(BlueprintEvent)
	void StartBeetleRide()
	{
		if (IsActorDisabled(this))
			EnableActor(this);

		for (auto Player : Game::GetPlayers())
		{
			StartRidingBeetle(Player, this);
		}

		InitializeCamera();

		bIsRunning = true;

		OnBeetleRideStart.Broadcast();
	}

	UFUNCTION()
	void StopBeetleRide()
	{
		for (auto Player : Game::GetPlayers())
		{
			StopRidingBeetle(Player);
			Player.StopAllCameraShakes();
			Player.DeactivateCameraByInstigator(this);
			Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
		}

		Capability::RemovePlayerCapabilitySheetRequest(TreeBeetleRidingCapabilitySheet);

		bCanBeControlled = false;
		bIsRunning = false;

		DisableActor(this);
	}

	UFUNCTION()
	void StartAtCheckpoint(ATreeBeetleRidingCheckpoint Checkpoint)
	{
		SplineFollowerComponent.Spline = Checkpoint.Spline;
		SplineFollowerComponent.SetDistanceAndOffset(Checkpoint.CheckpointDistance, 0.f);

		Location = SplineFollowerComponent.Transform.Location;
		Rotation = SplineFollowerComponent.Transform.Rotation;

		SetActorLocationAndRotation(Location, Rotation);

		CameraBlendSettings.BlendTime = 0.f;
		ViewPointBlendSpeed = EHazeViewPointBlendSpeed::Instant;

		// Snap replication follower
		FHazeSplineSystemPosition SplinePosition;
		SplinePosition.FromData(SplineFollowerComponent.Spline, SplineFollowerComponent.DistanceOnSpline, SplineFollowerComponent.bForwardDirection);
		ReplicatedSplineFollowComponent.ActivateSplineMovement(SplinePosition);

		StartBeetleRide();
	}

	UFUNCTION(BlueprintEvent)
	void Turn(FVector Input)
	{
		TurnForce.Y = Input.X * SideSpeed;
	}

	UFUNCTION(BlueprintEvent)
	void Dash()
	{
		if (bIsDashing)
			return;

		bIsDashing = true;

		DashTimer = DashCooldown;

		PrintScaled("Beetle Dash!", 1.f, FLinearColor::Green, 2.f);
		FVector DashVelocity = FVector(3000.f, 0.f, 0.f);
		
		Velocity += DashVelocity;
	}

	UFUNCTION(BlueprintEvent)
	void Jump()
	{
		if (HasControl())
		{
			if (!SplineFollowerComponent.bIsGrounded)
			PrintScaled("Failed Jump Not Grounded!", 1.f, FLinearColor::Red, 4.f);

			if (bIsDead)
				return;

			if (!SplineFollowerComponent.bIsGrounded && CoyoteTimer <= 0.f)
				return;

			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Jump"), FHazeDelegateCrumbParams());					
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Jump(const FHazeDelegateCrumbData& CrumbData)
	{
		SplineFollowerComponent.bIsGrounded = false;
		CoyoteTimer = 0.f;

		PrintScaled("Beetle Jump!", 1.f, FLinearColor::Green, 2.f);
		Niagara::SpawnSystemAtLocation(VFX_BeetleJump, ActorLocation);

		FVector JumpVelocity = FVector(1000.f, 0.f, 3500.f);
		
		Velocity += JumpVelocity;
		Velocity.Z = JumpVelocity.Z;

		bIsJumping = true;	
	}

	UFUNCTION()
	void TakeDamage(float Damage = 1.f, ETreeBeetleDamageType DamageType = ETreeBeetleDamageType::Collision)
	{
		if (Game::GetMay().GetGodMode() == EGodMode::God)
			return;

		if (bIsDead)
			return;

		if (DamageType == ETreeBeetleDamageType::LarvaBomb)
		{
			// Remote side decides
			if (Network::IsNetworked() && HasControl())
				return;

			UHazeCrumbComponent MayCrumbComponent = UHazeCrumbComponent::Get(Game::GetMay());
			if (MayCrumbComponent == nullptr)
				return;
			
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddValue(n"Damage", Damage);
			MayCrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_RemoteDamage"), CrumbParams);

			return;
		}

		if (!HasControl())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddValue(n"Damage", Damage);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Damage"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Damage(const FHazeDelegateCrumbData& CrumbData)
	{
		PrintScaled("Beetle Damage!", 1.f, FLinearColor::Green, 2.f);
		float Damage = CrumbData.GetValue(n"Damage");
		Health -= Damage;
		OnTakeDamage.Broadcast(Damage);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(TakeDamageForceFeedback, false, true, n"BeetleDamage");
			Player.PlayCameraShake(TakeDamageCameraShake, 0.4f);
		}

		if (Health <= 0.f)
			CrashOnGround();
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_RemoteDamage(const FHazeDelegateCrumbData& CrumbData)
	{
		float Damage = CrumbData.GetValue(n"Damage");
		Health -= Damage;
		OnTakeDamage.Broadcast(Damage);
		PrintScaled("Beetle Remote Damage!", 1.f, FLinearColor::Green, 2.f);

		if (Health <= 0.f)
		{
			if (HasControl())
			{
				CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_CrashOnGround"), FHazeDelegateCrumbParams());			
			}
			else
			{
				Health = 0.f;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Die(const FHazeDelegateCrumbData& CrumbData)
	{
		Die();
	}

	void Die()
	{
		bIsDead = true;
		bIsRunning = false;
		OnBeetleDie.Broadcast();
	}

	UFUNCTION()
	void Land()
	{
		if (HasControl())
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Land"), FHazeDelegateCrumbParams());					
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Land(const FHazeDelegateCrumbData& CrumbData)
	{
		bIsJumping = false;
		Niagara::SpawnSystemAtLocation(VFX_BeetleLand, ActorLocation);
	}	

	UFUNCTION()
	void CrashInAir()
	{		
		if (HasControl())
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_CrashInAir"), FHazeDelegateCrumbParams());					
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_CrashInAir(const FHazeDelegateCrumbData& CrumbData)
	{
		PrintToScreen("Air Crash!", 2.f);
		Niagara::SpawnSystemAtLocation(VFX_BeetleCrash, ActorLocation);
		bIsCrashingInAir = true;
		StartCameraTracking();
		Die();
	}

	UFUNCTION()
	void CrashOnGround()
	{
		if (HasControl())
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_CrashOnGround"), FHazeDelegateCrumbParams());					
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_CrashOnGround(const FHazeDelegateCrumbData& CrumbData)
	{
		PrintToScreen("Ground Crash!", 2.f);
		Niagara::SpawnSystemAtLocation(VFX_BeetleCrash, ActorLocation);
		bIsCrashingOnGround = true;
		Die();
	}

	UFUNCTION()
	void Fall()
	{
		if (HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddVector(n"Velocity", SplineFollowerComponent.Velocity);
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Fall"), CrumbParams);
		}
	}	

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Fall(const FHazeDelegateCrumbData& CrumbData)
	{
		PrintToScreen("Fall!", 2.f);
		bIsFalling = true;
		Velocity = CrumbData.GetVector(n"Velocity");
		StartCameraTracking();
		Die();
	}

	UFUNCTION(BlueprintEvent)
	void BeginRide()
	{
		InitializeCamera();
		bIsRunning = true;
	}

	void InitializeCamera()
	{
		PreviousCameraTransform = CameraRoot.AttachParent.WorldTransform * InitialRelativeCameraTransform;

		CameraRoot.DetachFromParent(true);

		Game::GetMay().ActivateCamera(Camera, CameraBlendSettings, this);
		Game::GetCody().ActivateCamera(Camera, CameraBlendSettings, this);

		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, ViewPointBlendSpeed);	
	}

	void StartCameraTracking()
	{
		FFocusTrackerTarget FocusTarget;
		FocusTarget.Focus.Actor = this;
		FocusTarget.Focus.Component = BeetleSkeletalMesh;
		FocusTarget.Weight = 1.f;
		FocusTrackerComponent.AddFocusTarget(FocusTarget);
	}

	void UpdateCamera(float DeltaTime)
	{
		FTransform TargetTransform = SplineFollowerComponent.GetSplineTransform();
		FVector TargetLocalLocation = PreviousCameraTransform.InverseTransformPosition(TargetTransform.Location);

		TargetLocalLocation += FVector::RightVector * SplineFollowerComponent.Offset * 0.5f;

		// Adjust Height below spline 0 (not groundZ) (Added Abs to make sure its not negative height)
		TargetLocalLocation += FVector::UpVector * FMath::Min(FMath::Abs(SplineFollowerComponent.Height), 0.f);

		FVector CurrentLocalLocation = FMath::VLerp(FVector::ZeroVector, TargetLocalLocation, FVector(10.f, 1.0f, 5.f) * DeltaTime); // LerpSpeeds FVector(10.f, 1.0f, 5.f)

		FVector CurrentWorldLocation = PreviousCameraTransform.TransformPosition(CurrentLocalLocation);

		// Lerp Rotation
		FQuat CameraRotation = FQuat::Slerp(CameraRoot.WorldTransform.Rotation, TargetTransform.Rotation, 5.f * DeltaTime);

//		CameraRoot.SetWorldLocationAndRotation(CurrentWorldLocation, TargetTransform.Rotator());
		CameraRoot.SetWorldLocationAndRotation(CurrentWorldLocation, CameraRotation);

		PreviousCameraTransform = CameraRoot.WorldTransform;

		FRotator Rot = Camera.WorldRotation;
		Rot.Roll = CameraRoot.WorldRotation.Roll;
		Camera.WorldRotation = Rot;
	}

	UFUNCTION()
	void OnGrounded()
	{
		PrintToScreen("OnGrounded()", 1.f);

		if (!SplineFollowerComponent.Spline.bIsGap)
			Land();
	
		if (SplineFollowerComponent.Spline.bIsGap && !SplineFollowerComponent.Spline.bGapHasBottom)
			Fall();

		if (SplineFollowerComponent.Spline.bIsGap && SplineFollowerComponent.Spline.bGapHasBottom)
			CrashInAir();
	}

	UFUNCTION()
	void OnFootPrintOverlap(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, UConnectedHeightSplineComponent OverlappingSpline, bool bForward)
	{
	//	PrintToScreen("OnFootPrintOverlap()", 1.f, FLinearColor::Purple);
		if (ConnectedHeightSplineFollowerComponent.Spline.bIsGap && bForward == ConnectedHeightSplineFollowerComponent.bForwardDirection)
		{
			if (IsCrashingIntoLedge(OverlappingSpline, bForward, ConnectedHeightSplineFollowerComponent.Offset, ConnectedHeightSplineFollowerComponent.Height))
				CrashInAir();
		}
	}

	UFUNCTION()
	void OnSplineTransition(UConnectedHeightSplineFollowerComponent ConnectedHeightSplineFollowerComponent, bool bForward)
	{	
	//	PrintToScreen("OnSplineTransition()", 1.f);
		// Transition from Gap to Ground
		if (ConnectedHeightSplineFollowerComponent.PreviousSpline.bIsGap)
		{
			if (IsCrashingIntoLedge(ConnectedHeightSplineFollowerComponent.Spline, bForward, ConnectedHeightSplineFollowerComponent.Offset, ConnectedHeightSplineFollowerComponent.Height))
				CrashInAir();
		}
	
		// Transition from Ground to Gap
		if (ConnectedHeightSplineFollowerComponent.Spline.bIsGap && !ConnectedHeightSplineFollowerComponent.PreviousSpline.bIsGap)
		{
		//	PrintToScreen("Into Gap!", 2.f, FLinearColor::Green);
			if (ConnectedHeightSplineFollowerComponent.bIsGrounded)
			{
				if (!ConnectedHeightSplineFollowerComponent.Spline.bAutoJump)
				{
					PrintToScreen("Jumped to late!", 2.f, FLinearColor::Red);
					ConnectedHeightSplineFollowerComponent.bIsGrounded = false;
					CoyoteTimer = CoyoteTime;
				//	Fall();
				}
				else
				{
					PrintToScreen("AutoJump!", 2.f, FLinearColor::Red);
					Jump();
				}
			}
		}
	}

	bool IsCrashingIntoLedge(UConnectedHeightSplineComponent Spline, bool bForward, float Offset, float Height)
	{
		float DistanceScale = bForward ? 0.f : 1.f;
		float Distance = Spline.SplineLength * DistanceScale;

		FTransform TranformAtDistance = Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World, true);

		float SplineWidth = TranformAtDistance.Scale3D.Y * Spline.BaseWidth;

		// - 0.001f to prevent offset to be 1.0 and sample next row
		float NormalizedOffset = FMath::Clamp(Offset / SplineWidth, -1.f, 1.f - 0.001f);

		float GroundZ = Spline.GetZAtDistanceAndOffset(Distance, NormalizedOffset);

		if (Height < GroundZ - JumpHeightMargin)
			return true;

		return false;
	}

	UFUNCTION()
	void OnOverlapSphereBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (!HasControl())
			return;

		ATreeWaterLarva TreeWaterLarva = Cast<ATreeWaterLarva>(OtherActor);
		if (TreeWaterLarva != nullptr)
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"Larva", TreeWaterLarva);
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ExplodeLarva"), CrumbParams);

			TakeDamage(2.f);
		}

		ATreeBeetleRidingObstacle Obstacle = Cast<ATreeBeetleRidingObstacle>(OtherActor);
		if (Obstacle != nullptr)
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"Obstacle", Obstacle);
			CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_BreakObstacle"), CrumbParams);

			TakeDamage(1.f);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_ExplodeLarva(const FHazeDelegateCrumbData& CrumbData)
	{
		ATreeWaterLarva TreeWaterLarva = Cast<ATreeWaterLarva>(	CrumbData.GetObject(n"Larva"));
		TreeWaterLarva.Explode();
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_BreakObstacle(const FHazeDelegateCrumbData& CrumbData)
	{
		ATreeBeetleRidingObstacle Obstacle = Cast<ATreeBeetleRidingObstacle>(CrumbData.GetObject(n"Obstacle"));
		Obstacle.Break(ActorLocation);
	}

}