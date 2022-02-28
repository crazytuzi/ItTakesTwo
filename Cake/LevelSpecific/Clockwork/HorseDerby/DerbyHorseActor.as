import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseSplineTrack;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseComponent;
import Vino.Camera.Actors.StaticCamera;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyPlayerComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;

event void FOnHorseDerbyMidGameExit(AHazePlayerCharacter CancelledPlayer);

enum EHorseDerbyActorState
{
	Default,
	Crouch,
	Jump
}

enum EHorseDerbyCollideState
{
	Available,
	RaceComplete
}

class ADerbyHorseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PoleRotationRoot;

	UPROPERTY(DefaultComponent, Attach = PoleRotationRoot)
	UStaticMeshComponent PoleMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HorseAttachPoint;

	UPROPERTY(DefaultComponent, Attach = HorseAttachPoint)
	USceneComponent HorseHeightRoot;

	UPROPERTY(DefaultComponent, Attach = HorseHeightRoot)
	UStaticMeshComponent HorseHoldingPole;

	UPROPERTY(DefaultComponent, Attach = HorseHeightRoot)
	USkeletalMeshComponent HorseMeshComp;

	UPROPERTY(DefaultComponent, Attach = HorseHeightRoot)
	UBoxComponent HorseCollision1;
	default HorseCollision1.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default HorseCollision1.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = HorseHeightRoot)
	UBoxComponent HorseCollision2;
	default HorseCollision2.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default HorseCollision2.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = HorseHeightRoot)
	UBoxComponent HorseCollision3;
	default HorseCollision3.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default HorseCollision3.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = HorseMeshComp)
	USceneComponent AttachPoint;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDerbyHorseComponent HorseComponent;

	UPROPERTY(DefaultComponent, Attach = HorseMeshComp)
	UHazeAkComponent DerbyHorseHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent JumpToLocation;

	EHorseDerbyActorState HorseDerbyActorState;

	EHorseDerbyCollideState HorseDerbyCollideState;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerInteractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerCancelInteractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerStopInteractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerReachedStartLineAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

//Variables

	UPROPERTY(Category = "Setup")
	ADerbyHorseSplineTrack SplineTrack;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect ImpactRumble;

	UPROPERTY(Category = "Setup")
	EHazePlayer TargetPlayer;

	UPROPERTY(Category = "Settings")
	float MovementSpeed = 250.f;

	UPROPERTY(Category = "Settings")
	float JumpHeight = 270.f;

	UPROPERTY(Category = "Settings")
	float CrouchHeight = 70.f;

	UPROPERTY(Category = "Settings")
	float JumpSpeed = 100.f;

	UPROPERTY(Category = "Settings")
	float CrouchSpeed = 100.f;

	UPROPERTY(Category = "Settings")
	float HitDisableTime = 1.5f;

	UPROPERTY(Category = "Settings")
	bool MayInteraction = false;

	bool bCanCancelMidGame;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCamera Camera;

	UPROPERTY(Category = "Settings")
	float InvincibilityTime = 1.5f;

	float StartingHeight;

	FOnHorseDerbyMidGameExit OnHorseDerbyMidGameExit;

	EDerbyHorseState HorseState;

	AHazePlayerCharacter InteractingPlayer;

	bool Collided = false;

	bool CollisionDisabled = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PoleMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PoleMesh) * CullDistanceMultiplier);
		HorseHoldingPole.SetCullDistance(Editor::GetDefaultCullingDistance(HorseHoldingPole) * CullDistanceMultiplier);
		HorseMeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(HorseMeshComp) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HorseHoldingPole.AttachToComponent(HorseMeshComp, n"Align", EAttachmentRule::KeepWorld);

		if(MayInteraction)
			SetControlSide(Game::May);
		else
			SetControlSide(Game::Cody);
		
		StartingHeight = HorseHeightRoot.RelativeLocation.Z;

		if(SplineTrack != nullptr)
			SetActorLocation(SplineTrack.GetWorldLocationAtStatePosition(EDerbyHorseState::Inactive));

		DerbyHorseHazeAkComp.SetTrackVelocity(true, 250.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HorseComponent.MovementState != EDerbyHorseMovementState::Crouch && HorseComponent.MovementState != EDerbyHorseMovementState::Jump)
		{
			float NewHeight = FMath::FInterpTo(HorseHeightRoot.RelativeLocation.Z, StartingHeight, DeltaTime, 7.f);
			HorseHeightRoot.SetRelativeLocation(FVector(HorseHeightRoot.RelativeLocation.X, HorseHeightRoot.RelativeLocation.Y, NewHeight));
		}
	}

	UFUNCTION()
	void HorseInteractedWith(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"DerbyHorseActor", this);
		Player.SetCapabilityActionState(n"HorseDerby", EHazeActionState::Active);
		Player.AttachToComponent(HorseMeshComp, n"Base", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		
		UTimeControlSequenceComponent SeqComp =  UTimeControlSequenceComponent::Get(Game::May);
		
		if (SeqComp != nullptr)
			SeqComp.DeactiveClone(Game::May);

		UHorseDerbyPlayerComponent PlayerComp = UHorseDerbyPlayerComponent::GetOrCreate(Player);
		PlayerComp.HorseComp = HorseComponent;

		DerbyHorseHazeAkComp.HazePostEvent(PlayerInteractAudioEvent);

		InteractingPlayer = Player;

		if(Camera != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 1.f;
			Camera.ActivateCamera(Player, Blend, this, Priority = EHazeCameraPriority::Script);
		}
	}

	void HorseInteracted(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"DerbyHorseActor", this);
		Player.SetCapabilityActionState(n"HorseDerby", EHazeActionState::Active);
		Player.AttachToComponent(HorseMeshComp, n"Base", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

		UTimeControlSequenceComponent SeqComp =  UTimeControlSequenceComponent::Get(Game::May);
		
		if (SeqComp != nullptr)
			SeqComp.DeactiveClone(Game::May);

		UHorseDerbyPlayerComponent PlayerComp = UHorseDerbyPlayerComponent::GetOrCreate(Player);
		PlayerComp.HorseComp = HorseComponent;

		DerbyHorseHazeAkComp.HazePostEvent(PlayerInteractAudioEvent);

		InteractingPlayer = Player;

		if(Camera != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 1.f;
			Camera.ActivateCamera(Player, Blend, this, Priority = EHazeCameraPriority::Script);
		}
	}

	//Fired When player cancels interaction.
	void InteractionDisabled(AHazePlayerCharacter Player)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.SetCapabilityActionState(n"HorseDerby", EHazeActionState::Inactive);

		DerbyHorseHazeAkComp.HazePostEvent(PlayerCancelInteractAudioEvent);

		if(Camera != nullptr)
			Camera.DeactivateCamera(Player);
		
		InteractingPlayer = nullptr;
	}

	UFUNCTION()
	void OnDerbyStarted()
	{
		SwitchState(EDerbyHorseState::GameActive);
	}

	//Called whenever a new position is reached (Awaiting = startline, Inactive = WhenNotInteracted, GameActive = playing, GameWon = a player has won)
	UFUNCTION(NetFunction)
	void SwitchState(EDerbyHorseState StateToUse)
	{
		switch(StateToUse)
		{
			case(EDerbyHorseState::AwaitingStart):
				HorseState = EDerbyHorseState::AwaitingStart;
				DerbyHorseHazeAkComp.HazePostEvent(PlayerReachedStartLineAudioEvent);
				DerbyHorseHazeAkComp.HazePostEvent(PlayerStopInteractAudioEvent);
				break;
			case(EDerbyHorseState::Inactive):
				HorseState = EDerbyHorseState::Inactive;
				DerbyHorseHazeAkComp.HazePostEvent(PlayerStopInteractAudioEvent);
				break;
			case(EDerbyHorseState::GameActive):
				HorseState = EDerbyHorseState::GameActive;
				break;
			case(EDerbyHorseState::GameWon):
				HorseState = EDerbyHorseState::GameWon;
				SetCapabilityActionState(n"Hit", EHazeActionState::Inactive);
				SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);
				SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);
				break;
			default:
				break;
		}
	}	

	UFUNCTION()
	void HitRumble()
	{
		if (InteractingPlayer != nullptr)
			InteractingPlayer.PlayForceFeedback(ImpactRumble, false, true, n"HorseDerbyImpact");
	}
}