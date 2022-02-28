import Peanuts.Spline.SplineComponent;
enum EAutoMoveMode
{
	None,
	WorldDirection,
	FollowActor,
	FollowSpline
}

class UCharacterAutoMoveComponent : UActorComponent
{
	EAutoMoveMode AutoMoveMode = EAutoMoveMode::None;
	float Duration = 0.f;

	// Move Forwards & Direction
	FVector MoveDirection = FVector::ZeroVector;
	// Follow Actor
	AActor ActorToFollow;
	// Follow Spline
	UHazeSplineComponent SplineToFollow;
	float ChaseDistance = 0.f;
	float LateralFollowOffset = 0.f;
	bool bInterruptOnPlayerInput = true;

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		Reset();
	}

	void Reset()
	{
		MoveDirection = FVector::ZeroVector;
		Duration = 0.f;
		ActorToFollow = nullptr;
		SplineToFollow = nullptr;
		ChaseDistance = 0.f;
		LateralFollowOffset = 0.f;

		AutoMoveMode = EAutoMoveMode::None;
	}
}

UFUNCTION(Category = "Auto Move")
void AutoMoveSetInterruptOnPlayerInput(AHazePlayerCharacter Player, bool bValue)
{
	if (Player == nullptr)
		return;

	UCharacterAutoMoveComponent AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Player);
	AutoMoveComp.bInterruptOnPlayerInput = bValue;
}

// Will cancel the auto move regardless of what mode the auto move is in
UFUNCTION(Category = "Auto Move")
void CancelAutoMoveCharacter(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;

	UCharacterAutoMoveComponent AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Player);
	AutoMoveComp.Reset();
}

// Will auto move in the forward vector of the player
UFUNCTION(Category = "Auto Move")
void AutoMoveCharacterForwards(AHazePlayerCharacter Player, float Duration = 5.f, bool bInterruptOnPlayerInput = true)
{
	if (Player == nullptr)
		return;
	
	if (Duration <= 0.f)
		return;

	UCharacterAutoMoveComponent AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Player);
	AutoMoveComp.bInterruptOnPlayerInput = bInterruptOnPlayerInput;
	AutoMoveComp.MoveDirection = Player.ActorForwardVector;
	AutoMoveComp.Duration = Duration;

	AutoMoveComp.AutoMoveMode = EAutoMoveMode::WorldDirection;
}

// Will auto move in the direction specified (in world space)
UFUNCTION(Category = "Auto Move")
void AutoMoveCharacterInDirection(AHazePlayerCharacter Player, FVector MoveDirection, float Duration = 5.f, bool bInterruptOnPlayerInput = true)
{
	if (Player == nullptr)
		return;
	
	if (Duration <= 0.f)
		return;

	UCharacterAutoMoveComponent AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Player);
	AutoMoveComp.bInterruptOnPlayerInput = bInterruptOnPlayerInput;
	AutoMoveComp.MoveDirection = MoveDirection.GetSafeNormal();
	AutoMoveComp.Duration = Duration;

	AutoMoveComp.AutoMoveMode = EAutoMoveMode::WorldDirection;
}

// Will auto move towards the actor. Will update location on tick to follow a moving target
UFUNCTION(Category = "Auto Move")
void AutoMoveCharacterTowardsActor(AHazePlayerCharacter Player, AActor TargetActor, float Duration = 5.f, bool bInterruptOnPlayerInput = true)
{
	if (Player == nullptr)
		return;

	if (TargetActor == nullptr)
		return;
	
	if (Duration <= 0.f)
		return;

	UCharacterAutoMoveComponent AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Player);
	AutoMoveComp.bInterruptOnPlayerInput = bInterruptOnPlayerInput;
	AutoMoveComp.ActorToFollow = TargetActor;
	AutoMoveComp.Duration = Duration;

	AutoMoveComp.AutoMoveMode = EAutoMoveMode::FollowActor;
}

/*
Will auto move towards nearest distance along spline + chase distance
LateralFollowOffset adds an offset in the right vector of the spline (use negative numbers for left). Use if you want the players to run side by side, not ontop of each other
*/
UFUNCTION(Category = "Auto Move")
void AutoMoveCharacterAlongSpline(AHazePlayerCharacter Player, UHazeSplineComponent SplineToFollow, float ChaseDistance = 50.f, float LateralFollowOffset = 0.f, float Duration = 5.f, bool bInterruptOnPlayerInput = true)
{
	if (Player == nullptr)
		return;

	if (SplineToFollow == nullptr)
		return;
	
	if (Duration <= 0.f)
		return;

	UCharacterAutoMoveComponent AutoMoveComp = UCharacterAutoMoveComponent::GetOrCreate(Player);
	AutoMoveComp.bInterruptOnPlayerInput = bInterruptOnPlayerInput;
	AutoMoveComp.SplineToFollow = SplineToFollow;
	AutoMoveComp.ChaseDistance = ChaseDistance;
	AutoMoveComp.LateralFollowOffset = LateralFollowOffset;
	AutoMoveComp.Duration = Duration;

	AutoMoveComp.AutoMoveMode = EAutoMoveMode::FollowSpline;
}

