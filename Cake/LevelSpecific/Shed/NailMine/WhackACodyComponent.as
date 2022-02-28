import Cake.LevelSpecific.Shed.NailMine.WhackABoard;
import Cake.LevelSpecific.Shed.Main.WhackACody_May;

class UWhackACodyComponent : UActorComponent
{
	UPROPERTY()
	AWhackABoard WhackABoardRef;

	UPROPERTY(Category = "Animations")
	TArray<UAnimSequence> CodyAnims;

	UPROPERTY(Category = "Animations")
	ULocomotionFeatureWhackACody MayAnimFeature;

	EWhackACodyDirection CurrentDir;
	bool bHasEntered = false;
	float PeekAlpha = 0.f;

	float PeekCooldown = 0.f;

	float HammerCooldown = 0.f;
	float TurnCooldown = 0.f;

	UFUNCTION()
	void SetPeekCooldown()
	{
		PeekCooldown = 1.2f;
	}

	EWhackACodyDirection DirectionFromInput(FVector2D Input)
	{
		if (Input.SizeSquared() < 0.8f)
			return EWhackACodyDirection::Neutral;

		// Clockwise angle of the input, where +X is 0 degrees and -Y is 90 degrees
		float StickAngle = FMath::RadiansToDegrees(FMath::Atan2(-Input.X, Input.Y));

		// [-180, 180] => [0, 360]
		StickAngle = Math::FWrap(StickAngle, 0, 360.f);
		return EWhackACodyDirection(FMath::RoundToInt(StickAngle / 90.f) % 4);
	}
}

void ActivateWhackACodyForPlayer(AHazePlayerCharacter PlayerRef, AWhackABoard WhackABoardRef)
{
	UWhackACodyComponent Comp = UWhackACodyComponent::Get(PlayerRef);
	Comp.WhackABoardRef = WhackABoardRef;
}