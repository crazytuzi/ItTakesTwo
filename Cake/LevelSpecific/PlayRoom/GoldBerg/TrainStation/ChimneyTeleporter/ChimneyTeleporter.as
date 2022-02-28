import Vino.Buttons.GroundPoundButton;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;

class AChimneyteleporter : AGroundPoundButton
{
	UPROPERTY()
	AHazeActor TeleportPosition;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent TeleportStartLocationFX;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent TeleportlocationFX;

	UPROPERTY(DefaultComponent, Attach = ButtonMesh)
	UStaticMeshComponent RightDoor;

	UPROPERTY(DefaultComponent, Attach = ButtonMesh)
	UStaticMeshComponent LeftDoor;

	UPROPERTY(DefaultComponent, Attach = ButtonMesh)
	UStaticMeshComponent Bottom;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TeleportAudioEvent;

	UPROPERTY()
	FHazeTimeLike ChimneyTimeLike;

	UPROPERTY()
	FHazeTimeLike RattleTimeLike;

	UPROPERTY()
	FHazeTimeLike ChimneyOpenTimeLike;

	float LeftRotationYaw = 0;
	float RightRotationYaw = 0;

	UPROPERTY()
	AChimneyteleporter LinkedChimney;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnButtonGroundPoundCompleted.AddUFunction(this, n"TeleportPlayer");
		OnButtonGroundPoundStarted.AddUFunction(this, n"FlipDoors");

		TeleportlocationFX.SetWorldLocation(TeleportPosition.ActorLocation);
		ChimneyTimeLike.BindUpdate(this, n"TimelikeUpdate");
		ChimneyOpenTimeLike.BindUpdate(this, n"ChimneyOpenTimelikeUpdate");
		RattleTimeLike.BindUpdate(this, n"RattleUpdate");
		PlayRattle();
	}

	UFUNCTION()
	void FlipDoors(AHazePlayerCharacter Player)
	{
		ChimneyTimeLike.PlayFromStart();
		Player.PlayerHazeAkComp.HazePostEvent(TeleportAudioEvent);
	}

	UFUNCTION()
	void PlayRattle()
	{
		RattleTimeLike.PlayFromStart();
		float Random = FMath::RandRange(5.f, 10.f);
		System::SetTimer(this, n"PlayRattle", Random, true);
	}

	UFUNCTION()
	void OpenForPlayer()
	{
		ChimneyOpenTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void RattleUpdate(float Alpha)
	{
		FRotator LeftRotation = LeftDoor.RelativeRotation;
		FRotator RightRotation = RightDoor.RelativeRotation;;

		LeftRotation.Pitch = FMath::Lerp(1.5f, -1.5f, Alpha);
		RightRotation.Pitch = FMath::Lerp(1.5f, -1.5f, Alpha);

		RightDoor.RelativeRotation = RightRotation;
		LeftDoor.RelativeRotation = LeftRotation;
	}

	UFUNCTION()
	void ChimneyOpenTimelikeUpdate(float Alpha)
	{
		FRotator LeftRotation = LeftDoor.RelativeRotation;
		FRotator RightRotation = RightDoor.RelativeRotation;;

		LeftRotation.Pitch = Alpha;
		RightRotation.Pitch = Alpha;

		RightDoor.RelativeRotation = RightRotation;
		LeftDoor.RelativeRotation = LeftRotation;
	}

	UFUNCTION()
	void TimelikeUpdate(float Alpha)
	{
		FRotator LeftRotation = LeftDoor.RelativeRotation;
		FRotator RightRotation = RightDoor.RelativeRotation;;

		LeftRotation.Pitch = FMath::Lerp(0.f, -87.f, Alpha);
		RightRotation.Pitch = FMath::Lerp(0.f, -87.f, Alpha);

		RightDoor.RelativeRotation = RightRotation;
		LeftDoor.RelativeRotation = LeftRotation;
	}

	UFUNCTION()
	void TeleportPlayer(AHazePlayerCharacter Player)
	{
		Player.TeleportActor(TeleportPosition.ActorLocation, TeleportPosition.ActorRotation);
		Player.SnapCameraBehindPlayer();

		UCharacterGroundPoundComponent CharGroundPoundComp = UCharacterGroundPoundComponent::Get(Player);
		if (CharGroundPoundComp != nullptr)
			CharGroundPoundComp.ResetState();
		
		Player.MovementComponent.AddImpulse(FVector::UpVector * 3000);
		TeleportStartLocationFX.Activate(true);
		TeleportlocationFX.Activate(true);
		System::SetTimer(this, n"Reverse", 0.2f, false);
		LinkedChimney.OpenForPlayer();
	}

	UFUNCTION()
	void Reverse()
	{
		ChimneyTimeLike.ReverseFromEnd();
	}
}