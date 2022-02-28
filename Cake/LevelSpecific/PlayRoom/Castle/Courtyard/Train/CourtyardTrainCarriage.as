import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainTrack;
event void FOnCarriageRidden(AHazePlayerCharacter Player);

class ACourtyardTrainCarriage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent SmallWheelsFront;
	default SmallWheelsFront.bUseAttachParentBound = true;
	default SmallWheelsFront.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent SmallWheelsRear;
	default SmallWheelsRear.bUseAttachParentBound = true;
	default SmallWheelsRear.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent FrontHook;

	UPROPERTY(DefaultComponent, Attach = FrontHook)
	USceneComponent HookRoot;
	UPROPERTY(DefaultComponent, Attach = HookRoot)
	UStaticMeshComponent HookMesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent RearHook;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent CarriageAkComp;

	UPROPERTY()
	float Wheelbase = 200.f;

	UPROPERTY()
	FOnCarriageRidden OnCarriageRidden;

	UPROPERTY()
	ACourtyardTrainTrack Track;

	UPROPERTY()
	UHazeCrumbComponent TrainCrumbComp;
	
	UPROPERTY()
	float Speed = 0.f;
	UPROPERTY()
	float Angle = 0.f;
}