import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeSlideCapability;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeJumpCapability;
import Vino.Movement.Capabilities.Sliding.SlidingNames;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Capabilities.CameraSplineSlopeSlideChaseCapability;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSplineSlopeAirDashCapability;


const FName OtherMovementBlocker = n"SplineSlopeSliding";

UFUNCTION(Category = "Movement|SlopeSliding")
void StartSplineSlopeSliding(AHazePlayerCharacter Player, USlopeSlidingSplineComponent SlopeSpline)
{
	if (!ensure(SlopeSpline != nullptr))
		return;

	UCharacterSlopeSlideComponent SlidingComponent = UCharacterSlopeSlideComponent::GetOrCreate(Player);
	SlidingComponent.GuideSpline = SlopeSpline;

    Player.AddCapability(UCharacterSplineSlopeSlideCapability::StaticClass());
	Player.AddCapability(UCharacterSplineSlopeJumpCapability::StaticClass());
	Player.AddCapability(UCharacterSplopeSlopeAirDashCapability::StaticClass());
	Player.AddCapability(UCameraSplineSlopeSlideChaseCapability::StaticClass());
	
	Player.BlockCapabilities(MovementSystemTags::n"AirJump", OtherMovementBlocker);
	Player.BlockCapabilities(MovementSystemTags::Dash, OtherMovementBlocker);
	Player.BlockCapabilities(MovementSystemTags::WallSlide, OtherMovementBlocker);
	Player.BlockCapabilities(MovementSystemTags::GroundPound, OtherMovementBlocker);
	Player.BlockCapabilities(MovementSystemTags::Sprint, OtherMovementBlocker);
	Player.BlockCapabilities(MovementSystemTags::Crouch, OtherMovementBlocker);

	UMovementSettings::SetStepUpAmount(Player, 100.f, Instigator = SlopeSpline);
	UMovementSettings::SetActorMaxFallSpeed(Player, 5000.f, Instigator = SlopeSpline);
}

UFUNCTION(Category = "Movement|SlopeSliding")
void StopSplineSlopeSliding(AHazePlayerCharacter Player)
{
	UCharacterSlopeSlideComponent SlidingComponent = UCharacterSlopeSlideComponent::Get(Player);
	if (!ensure(SlidingComponent != nullptr))
		return;

	Player.UnblockCapabilities(MovementSystemTags::n"AirJump", OtherMovementBlocker);
	Player.UnblockCapabilities(MovementSystemTags::Dash, OtherMovementBlocker);
	Player.UnblockCapabilities(MovementSystemTags::WallSlide, OtherMovementBlocker);
	Player.UnblockCapabilities(MovementSystemTags::GroundPound, OtherMovementBlocker);
	Player.UnblockCapabilities(MovementSystemTags::Sprint, OtherMovementBlocker);
	Player.UnblockCapabilities(MovementSystemTags::Crouch, OtherMovementBlocker);

	Player.RemoveCapability(UCharacterSplineSlopeSlideCapability::StaticClass());
	Player.RemoveCapability(UCharacterSplineSlopeJumpCapability::StaticClass());
	Player.RemoveCapability(UCameraSplineSlopeSlideChaseCapability::StaticClass());

	Player.ClearSettingsByInstigator(SlidingComponent.GuideSpline);
}
