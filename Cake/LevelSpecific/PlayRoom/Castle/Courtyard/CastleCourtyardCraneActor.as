import Vino.Camera.Actors.StaticCamera;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneAttachedActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneMagnet;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Crane.CastleCourtyardCraneSettings;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;
import Peanuts.Foghorn.FoghornStatics;

event void FOnBothPlayersOnCraneStart();
event void FOnBothPlayersOnCraneStop();

event void FOnCraneInPosition();
event void FOnCraneOutOfPosition();

class ACastleCourtyardCraneActor : AHazeActor
{
//Compontents
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent  Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent CraneMesh;

	UPROPERTY(DefaultComponent, Attach = CraneMesh)
	USceneComponent CrankRoot;

	UPROPERTY(DefaultComponent, Attach = CrankRoot)
	UStaticMeshComponent BottomCoilMesh;

	UPROPERTY(DefaultComponent, Attach = CraneMesh)
	UStaticMeshComponent TopCoilMesh;	

	UPROPERTY(DefaultComponent, Attach = CrankRoot)
	UStaticMeshComponent CrankMesh;

	UPROPERTY(DefaultComponent, Attach = CraneMesh)
	UInteractionComponent CraneRotationInteractComp;

	UPROPERTY(DefaultComponent, Attach = CraneMesh)
	UInteractionComponent CraneHeightInteractionComp;

	UPROPERTY(DefaultComponent, Attach = CraneMesh)
	UStaticMeshComponent ConstraintPoint;

	UPROPERTY(DefaultComponent, Attach = ConstraintPoint)
	UHazeCableComponent CableComp;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UHazeAkComponent CraneBaseHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = TopCoilMesh)
	UHazeAkComponent CraneTopHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = BottomCoilMesh)
	UHazeAkComponent PulleyHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedTargetYaw;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedTargetConstrainLength;
	default SyncedTargetConstrainLength.Value = 100.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AttachWreckingBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CraneMovementCreakAudioEvent;

//Variables - Settings
	UPROPERTY(Category = "References")
	AStaticCamera CraneRotationCam;

	UPROPERTY(Category = "References")
	AStaticCamera CraneHeightCam;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UHazeCapability> CastleCraneRotationCapability;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UHazeCapability> CastleCraneHeightCapability;

	UPROPERTY(Category = "Settings")
	FCraneRotationSettings RotationSettings;

	UPROPERTY(Category = "Settings")
	FCraneConstraintSettings ConstraintSettings;	

	UPROPERTY(Category = "Settings")
	FCraneAlignSettings AlignSettings;

	UPROPERTY()
	FOnCraneInPosition OnCraneInPosition;
	UPROPERTY()
	FOnCraneOutOfPosition OnCraneOutOfPosition;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	UPROPERTY()
	FOnBothPlayersOnCraneStart OnBothPlayersOnCraneStart;
	UPROPERTY()
	FOnBothPlayersOnCraneStop OnBothPlayersOnCraneStop;
	
//Internal Variables - References
	//bool bCraneRotationInteractedWith;
	// bool bCraneHeightInteractedWith;
	float CrankProgress = 0.f;

	bool bBallAttached = false;
	bool bBallInRange = false;

	bool bBallAttachmentInProgress = false;

	bool bInteractionsEnabled = false;

	AHazePlayerCharacter PlayerRotatingCrane;
	AHazePlayerCharacter PlayerControllingHeight;

	UPROPERTY()
	ACourtyardCraneAttachedActor DefaultAttachedActor;
	ACourtyardCraneAttachedActor CurrentAttachedActor;

	FHazeAcceleratedFloat AcceleratedYaw;
	FHazeAcceleratedFloat AcceleratedConstraintLength;

	UPROPERTY()
	float MaximumRotation = 118.f;

	UPROPERTY()
	float DoorRotation = 335.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(CastleCraneRotationCapability);
		Capability::AddPlayerCapabilityRequest(CastleCraneHeightCapability);

		//Bind Events
		CraneRotationInteractComp.OnActivated.AddUFunction(this, n"OnInteractedCraneRotation");
		CraneHeightInteractionComp.OnActivated.AddUFunction(this, n"OnInteractedCraneHeight");

		CraneRotationCam.AttachToComponent(CraneMesh, NAME_None, EAttachmentRule::KeepWorld);
		CraneHeightCam.AttachToComponent(CraneMesh, NAME_None, EAttachmentRule::KeepWorld);

		SyncedTargetYaw.Value = CraneMesh.RelativeRotation.Yaw;
		AcceleratedYaw.SnapTo(SyncedTargetYaw.Value);

		if(DefaultAttachedActor != nullptr)
		{
			SyncedTargetConstrainLength.Value = FMath::Abs((ConstraintPoint.GetWorldLocation() - DefaultAttachedActor.GetActorLocation()).Size());
			AcceleratedConstraintLength.SnapTo(SyncedTargetConstrainLength.Value);

			AttachMagnet(DefaultAttachedActor);
			CableComp.SetAttachEndToComponent(ConstraintPoint);
			CableComp.AttachTo(DefaultAttachedActor.MeshComp);

			CurrentAttachedActor = DefaultAttachedActor;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(CastleCraneRotationCapability);
		Capability::RemovePlayerCapabilityRequest(CastleCraneHeightCapability);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerControllingHeight == nullptr)
			CrankProgress = FMath::FInterpConstantTo(CrankProgress, 0.f, DeltaTime, 2.f);
		CrankRoot.SetRelativeRotation(FRotator((1 - CrankProgress) * 360.f, 0.f, 0.f));

		// If the crane is nearby the door rotation, it should align the rotation and tether length
		if (SyncedTargetYaw.HasControl() && FMath::IsNearlyEqual(-DoorRotation, SyncedTargetYaw.Value, AlignSettings.AcceptanceAngle))
			SyncedTargetYaw.Value = FMath::FInterpConstantTo(SyncedTargetYaw.Value, -DoorRotation, DeltaTime, AlignSettings.RotationInterpSpeed);

		if (SyncedTargetConstrainLength.HasControl() && FMath::IsNearlyEqual(-DoorRotation, SyncedTargetYaw.Value, AlignSettings.AcceptanceAngle))
			SyncedTargetConstrainLength.Value = FMath::FInterpConstantTo(SyncedTargetConstrainLength.Value, ConstraintSettings.MaximumLength, DeltaTime, AlignSettings.HeightInterpSpeed);

		// Rotation
		float NewYaw = AcceleratedYaw.AccelerateTo(SyncedTargetYaw.Value, RotationSettings.AccelerationDuration, DeltaTime);
		CraneMesh.SetRelativeRotation(FRotator(0.f, NewYaw, 0.f));

		// Constraint Length
		AcceleratedConstraintLength.AccelerateTo(SyncedTargetConstrainLength.Value, ConstraintSettings.AccelerationDuration, DeltaTime);

		if (HasControl() && bBallAttached)
		{
			ACourtyardCraneWreckingBall Ball = Cast<ACourtyardCraneWreckingBall>(CurrentAttachedActor);
			if (FMath::IsNearlyEqual(-DoorRotation, AcceleratedYaw.Value, AlignSettings.AcceptanceAngle))
			{
				if (!bInteractionsEnabled)
				{
					NetEnableInteractions();
					NetEnableCollision();
					NetPlayWreckingBallBark(PlayerRotatingCrane);
				}
			}
			else
			{
				if (bInteractionsEnabled)
					NetDisableInteractions();
			}
		}	
	}

	UFUNCTION(NetFunction)
	void NetEnableInteractions()
	{
		bInteractionsEnabled = true;
		
		ACourtyardCraneWreckingBall Ball = Cast<ACourtyardCraneWreckingBall>(CurrentAttachedActor);
		Ball.LeftInteractComp.Enable(n"Connected");
		Ball.RightInteractComp.Enable(n"Connected");

	 	OnCraneInPosition.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetDisableInteractions()
	{
		bInteractionsEnabled = false;

		ACourtyardCraneWreckingBall Ball = Cast<ACourtyardCraneWreckingBall>(CurrentAttachedActor);
		Ball.LeftInteractComp.Disable(n"Connected");
		Ball.RightInteractComp.Disable(n"Connected");

	 	OnCraneOutOfPosition.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetPlayWreckingBallBark(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return;

		FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleCourtyardWreckingBallHintMay" : n"FoghornDBPlayroomCastleCourtyardWreckingBallHintCody";
		PlayFoghornVOBankEvent(VOBank, EventName);
	}

	UFUNCTION(NetFunction)
	void NetEnableCollision()
	{
		ACourtyardCraneWreckingBall Ball = Cast<ACourtyardCraneWreckingBall>(CurrentAttachedActor);
		Ball.CollisionTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION()
	void OnInteractedCraneRotation(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"CraneActor", this);

		// Disable interactions
		CraneRotationInteractComp.Disable(n"Interacting");
		CraneHeightInteractionComp.DisableForPlayer(Player, n"OtherInUse");

		PlayerRotatingCrane = Player;

		if (CraneRotationCam != nullptr)
			CraneRotationCam.ActivateCamera(Player, FHazeCameraBlendSettings(1.5f), this);

		if (PlayerRotatingCrane != nullptr && PlayerControllingHeight != nullptr)
			OnBothPlayersOnCraneStart.Broadcast();

		PlayHintBark();
	}

	UFUNCTION()
	void OnInteractedCraneHeight(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"CraneActor", this);

		// Disable interactions
		CraneHeightInteractionComp.Disable(n"InUse");
		CraneRotationInteractComp.DisableForPlayer(Player, n"OtherInUse");

		PlayerControllingHeight = Player;

		if (CraneHeightCam != nullptr)
			CraneHeightCam.ActivateCamera(Player, FHazeCameraBlendSettings(1.5f), this);

		if (PlayerRotatingCrane != nullptr && PlayerControllingHeight != nullptr)
			OnBothPlayersOnCraneStart.Broadcast();

		PlayHintBark();
	}

	void CraneRotationDeactivated(AHazePlayerCharacter Player)
	{
		if(CraneRotationCam != nullptr)
			CraneRotationCam.DeactivateCamera(Player, 1.5f);

		PlayerRotatingCrane = nullptr;

		// Enable interactions
		CraneRotationInteractComp.Enable(n"Interacting");
		CraneHeightInteractionComp.EnableForPlayer(Player, n"OtherInUse");

		OnBothPlayersOnCraneStop.Broadcast();
	}

	void CraneHeightDeactivated(AHazePlayerCharacter Player)
	{
		if(CraneHeightCam != nullptr)
			CraneHeightCam.DeactivateCamera(Player, 1.5f);

		PlayerControllingHeight = nullptr;

		// Enable interactions
		CraneHeightInteractionComp.Enable(n"InUse");
		CraneRotationInteractComp.EnableForPlayer(Player, n"OtherInUse");

		OnBothPlayersOnCraneStop.Broadcast();
	}

	void PlayHintBark()
	{
		if (PlayerControllingHeight != nullptr && PlayerRotatingCrane != nullptr)
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleCourtyardCraneHint");
	}

	UFUNCTION(NetFunction)
	void AttachMagnet(AHazeActor Object)
	{
		ACourtyardCraneMagnet MagnetActor = Cast<ACourtyardCraneMagnet>(Object);
		if(MagnetActor != nullptr)
		{
			Object.SetCapabilityAttributeValue(n"ConstraintLength", AcceleratedConstraintLength.Value);
			Object.SetCapabilityActionState(n"Attached", EHazeActionState::Active);
			Object.SetCapabilityAttributeObject(n"CraneActor", this);

			MagnetActor.AttachToCrane(this, ConstraintPoint);
			MagnetActor.CraneActorRef = this;

			MagnetActor.OnAttachWreckingBall.AddUFunction(this, n"AttachWreckingBall");
			MagnetActor.OnOverlapWreckingBall.AddUFunction(this, n"SetStartAttachBall");
		}
	}

	UFUNCTION()
	void AttachWreckingBall(ACourtyardCraneWreckingBall Object)
	{
		ACourtyardCraneWreckingBall BallActor = Cast<ACourtyardCraneWreckingBall>(Object);
		if (BallActor == nullptr)
			return;

		if (HasControl())
		{
			NetAttachWreckingBall(Object);
		}	
	}

	UFUNCTION(NetFunction)
	void NetAttachWreckingBall(ACourtyardCraneWreckingBall Object)
	{		
		ACourtyardCraneWreckingBall BallActor = Cast<ACourtyardCraneWreckingBall>(Object);
		if (BallActor == nullptr)
			return;

		ConstraintSettings.MaximumLength = 2050.f;
		SyncedTargetConstrainLength.Value = 2050.f;

		float ConstraintLength = (ConstraintPoint.GetWorldLocation() - Object.GetActorLocation()).Size();
		AcceleratedConstraintLength.SnapTo(ConstraintLength);

		BallActor.OnAttachComplete.AddUFunction(this, n"NetSetAttachFinished");
		Object.SetCapabilityAttributeObject(n"ConstraintPoint", ConstraintPoint);
		Object.SetCapabilityAttributeObject(n"CraneActor", this);

		ConstraintSettings.MinimumLength = 1200.f;
		MaximumRotation = 335.f;
		bBallAttached = true;
		CurrentAttachedActor = BallActor;
		BallActor.AttachToCrane(this, ConstraintPoint);

		CraneTopHazeAkComp.HazePostEvent(AttachWreckingBallAudioEvent);		
	}

	UFUNCTION()
	void SetStartAttachBall()
	{
		bBallAttachmentInProgress = true;
	}

	UFUNCTION(NetFunction)
	void NetSetAttachFinished()
	{
		bBallAttachmentInProgress = false;
	}
}

struct FCraneThreeShotSequence
{
    UPROPERTY()
    UAnimSequence Enter;

    UPROPERTY()
    UAnimSequence MH;

    UPROPERTY()
    UAnimSequence Exit;
}

struct FCraneRotationAnimations
{
    UPROPERTY()
    UAnimSequence Enter;

    UPROPERTY()
    UAnimSequence Exit;
}