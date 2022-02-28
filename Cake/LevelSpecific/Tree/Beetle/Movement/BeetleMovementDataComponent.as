import Cake.LevelSpecific.Tree.Beetle.Settings.BeetleSettings;

enum EBeetleMovementType
{
	None,
	Walk,
    Leap,
}

class UBeetleMovementDataComponent : UActorComponent
{
	EBeetleMovementType MoveType = EBeetleMovementType::Walk;
	bool bHasDestination = false;
	FVector Destination;
	float Speed = 0.f;
	float TurnDuration = 3.f;
	UBeetleSettings Settings;
	AHazeActor HazeOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		Settings = UBeetleSettings::GetSettings(HazeOwner);
	}

	void MoveTo(const FVector& MoveTowards, float MoveSpeed, float TurnDur)
	{
		MoveType = EBeetleMovementType::Walk;
		bHasDestination = true;
		Destination = MoveTowards;
		Speed = MoveSpeed;
		TurnDuration = TurnDur;
	}

	void LeapTo(const FVector& LeapDestination, float LeapSpeed)
	{
		MoveType = EBeetleMovementType::Leap;
		bHasDestination = true;
		Destination = LeapDestination;
		Speed = LeapSpeed;
	}

	void TurnInPlace(const FVector& TurnTowards, float TurnDur)
	{
		MoveType = EBeetleMovementType::Walk;
		bHasDestination = true;
		Destination = TurnTowards;
		Speed = 0.f;
		TurnDuration = TurnDur;
	}
}
