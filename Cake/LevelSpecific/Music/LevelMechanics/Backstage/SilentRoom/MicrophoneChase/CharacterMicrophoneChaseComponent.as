import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseDoor;
import Peanuts.AutoMove.CharacterAutoMoveComponent;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseElectricity;

void SetMicrophoneChaseDoor(AHazeActor TargetActor, AMicrophoneChaseDoor NewDoor)
{
	UCharacterMicrophoneChaseComponent Chase = UCharacterMicrophoneChaseComponent::Get(TargetActor);

	if(Chase != nullptr)
	{
		Chase.Door = NewDoor;
	}
}

bool HasCharacterMicrphoneChaseComponent(AHazeActor TargetActor)
{
	UCharacterMicrophoneChaseComponent Chase = UCharacterMicrophoneChaseComponent::Get(TargetActor);
	return Chase != nullptr;
}

UFUNCTION()
void MicrophoneChase_SetLastGrind(AHazePlayerCharacter Player, bool bValue)
{
	UCharacterMicrophoneChaseComponent ChaseComp = UCharacterMicrophoneChaseComponent::Get(Player);

	if(ChaseComp != nullptr)
	{
		ChaseComp.bLastGrind = bValue;
	}
}

UFUNCTION()
void MicrophoneChase_SetQuicktimeEvent(AHazePlayerCharacter Player, bool bQuicktimeEvent)
{
	UCharacterMicrophoneChaseComponent ChaseComp = UCharacterMicrophoneChaseComponent::Get(Player);

	if(ChaseComp != nullptr)
	{
		ChaseComp.bQuicktimeEvent = bQuicktimeEvent;
	}
}

UFUNCTION()
void MicrophoneChase_SetDone(AHazePlayerCharacter Player, bool bValue)
{
	UCharacterMicrophoneChaseComponent ChaseComp = UCharacterMicrophoneChaseComponent::Get(Player);

	if(ChaseComp != nullptr)
	{
		ChaseComp.bMicrophoneChaseDone = bValue;
	}
}

class UCharacterMicrophoneChaseComponent : UActorComponent
{
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ChaseCamSettings;

	AHazePlayerCharacter Player;
	ACheckpoint CurrentCheckpoint;
	AMicrophoneChaseDoor Door;
	bool bAllowRespawn = false;
	bool bKilledByMicrophoneMonster = false;
	bool bQuicktimeEvent = false;
	bool bLastGrind = false;
	bool bMicrophoneChaseDone = false;

	UPROPERTY()
	UMovementSettings ChaseMoveSettings;

	UPROPERTY()
	UMovementSettings ChaseLastGrindMoveSettings;

	UPROPERTY(Category = Animation)
	UAnimSequence CodyPushDoorAnim;

	UPROPERTY(Category = Animation)
	UAnimSequence MayPushDoorAnim;

	UPROPERTY(Category = Animation)
	UHazeLocomotionFeatureBase CodyDoorFeature;

	UPROPERTY(Category = Animation)
	UHazeLocomotionFeatureBase MayDoorFeature;

	UPROPERTY()
	UNiagaraSystem RespawnFX;

	UPROPERTY()
	AActor CodyGrindActor;

	UPROPERTY()
	AActor MayGrindActor;

	UPROPERTY()
	float AdditionalJumpToHeight = 0.f;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> OutOfScreenDeathEffect;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> ElectricityDeathFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}
