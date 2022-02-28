import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCartSettings;

// Base class for a rail cart
// Used by the pump-cart that players interact with, and the explosive carriage that follows it
class ARailCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	USceneComponent TiltRoot;
	
	UPROPERTY(DefaultComponent, Attach = TiltRoot)
	USceneComponent OffsetRoot;

	UPROPERTY(DefaultComponent, Attach = OffsetRoot)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "Animation")
	float BackWheelAngle = 0.f;

	UPROPERTY(Category = "Animation")
	float FrontWheelAngle = 0.f;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RailCollisionEvent;

	UPROPERTY(Category = "Physics")
	float Weight = 1.f;

	FHazeSplineSystemPosition Position;

	UPROPERTY(BlueprintReadOnly)
	float Speed = 0.f;

	// Returns if the cart is currently attached to a spline
	bool IsAttachedToSpline()
	{
		return Position.IsOnValidSpline();
	}
}