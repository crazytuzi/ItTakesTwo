import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCart;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;
import Peanuts.Audio.AudioStatics;

class URailCartOffsetCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Physics);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 70;

	ARailCart Cart;
	ARailPumpCart PumpCart;
	float DistanceOffset = 100.f;

	UHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cart = Cast<ARailCart>(Owner);
		PumpCart = Cast<ARailPumpCart>(Owner);
		HazeAkComp = UHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Cart.IsAttachedToSpline())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Cart.IsAttachedToSpline())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeSplineSystemPosition Position = Cart.Position;
		FHazeSplineSystemPosition Position_Front = Position;
		Position_Front.Move(DistanceOffset);

		FHazeSplineSystemPosition Position_Back = Position;
		Position_Back.Move(-DistanceOffset);

		// Get locations of the wheels
		FVector Location_Mid = Position.GetWorldLocation();
		FVector Location_Front = Position_Front.GetWorldLocation();
		FVector Location_Back = Position_Back.GetWorldLocation();

		// The target mid position (root of cart) should be in-between the front and back wheels
		FVector TargetMidPos = (Location_Front + Location_Back) / 2.f;
		FVector Diff = TargetMidPos - Location_Mid;

		// Transform the offset into relative space for the cart root
		FTransform CartTransform = Cart.Root.RelativeTransform;	
		Diff = CartTransform.InverseTransformVector(Diff);
		Cart.OffsetRoot.SetRelativeLocation(Diff);

		// Find out how much each wheel is turning to fit the track
		FVector Direction_Mid = Position.GetWorldForwardVector();
		FVector Direction_Front = Position_Front.GetWorldForwardVector();
		FVector Direction_Back = Position_Back.GetWorldForwardVector();

		FVector UpVector = Position.GetWorldUpVector();

		// Front wheels
		Cart.FrontWheelAngle = Direction_Mid.CrossProduct(Direction_Front).DotProduct(UpVector);
		Cart.FrontWheelAngle *= RAD_TO_DEG;

		// Back wheels
		Cart.BackWheelAngle = Direction_Mid.CrossProduct(Direction_Back).DotProduct(UpVector);
		Cart.BackWheelAngle *= RAD_TO_DEG;

		// Notify audio!
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::RailCartWheelAngle, FMath::Abs(Cart.FrontWheelAngle / 90.f), 0);
		if(PumpCart != nullptr)
			PumpCart.WheelAngle = FMath::Abs(Cart.FrontWheelAngle / 90.f);
	}
}