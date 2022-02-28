import Peanuts.Spline.SplineActor;
class AMarbleMazeMouse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase MouseSkelMesh;

	UPROPERTY(DefaultComponent, Attach = MouseSkelMesh, AttachSocket = Base)
	UStaticMeshComponent MouseHook;

	UPROPERTY(DefaultComponent, Attach = MouseSkelMesh, AttachSocket = Base)
	UStaticMeshComponent KnotMesh;

	UPROPERTY()
	AActor CableAttach;

	UPROPERTY()
	ASplineActor ConnectedSplineActor;

	UPROPERTY()
	UAnimSequence MouseBwd;

	UPROPERTY()
	UAnimSequence MouseFwd;

	UPROPERTY()
	UAnimSequence MouseFwdStart;

	UPROPERTY()
	UAnimSequence MouseMh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CableAttach.AttachToComponent(MouseSkelMesh, n"Base", EAttachmentRule::KeepWorld);
	}
}