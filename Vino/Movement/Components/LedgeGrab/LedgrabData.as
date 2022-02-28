import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.LedgeGrab.CharacterLedgeGrabSettings;
import Vino.Movement.Components.GrabbedCallbackComponent;

struct FLedgeGrabPhysicalData
{
	FHitResult ForwardHit;

	UPrimitiveComponent LedgeGrabbed = nullptr;
	UGrabbedCallbackComponent LedgeGrabCallbackComponent = nullptr;
	FVector NormalPointingAwayFromWall = FVector::ZeroVector;

	// Wanted hand locations when character is idling in hang	
	FTransform LeftHandRelative = FTransform::Identity;	
	FTransform RightHandRelative = FTransform::Identity;

	// Wanted Actor location when character is idling in hang.
	FTransform ActorHangLocation = FTransform::Identity;

	UPhysicalMaterial ContactMat = nullptr;

	void Reset()
	{
		ForwardHit = FHitResult();
		NormalPointingAwayFromWall = FVector();
		LedgeGrabbed = nullptr;
		LedgeGrabCallbackComponent = nullptr;
		ContactMat = nullptr;
		LeftHandRelative = FTransform::Identity;
		RightHandRelative = FTransform::Identity;
		ActorHangLocation = FTransform::Identity;
	}

	bool IsValid() const
	{
		return !NormalPointingAwayFromWall.IsNearlyZero();
	}

	bool opEquals(const FLedgeGrabPhysicalData& Other)
	{
		if (LedgeGrabbed != Other.LedgeGrabbed)
			return false;
		
		if (!NormalPointingAwayFromWall.Equals(Other.NormalPointingAwayFromWall))
			return false;

		if (!ActorHangLocation.Equals(Other.ActorHangLocation))
			return false;
		
		if (!LeftHandRelative.Equals(Other.LeftHandRelative))
			return false;
		
		if (!RightHandRelative.Equals(Other.RightHandRelative))
			return false;

		return true;
	}
}

struct FLedgeGrabCheckData
{
	const UHazeMovementComponent MoveComp = nullptr;
	const AHazePlayerCharacter OwningPlayer = nullptr;
	FCharacterLedgeGrabSettings Settings;
}
