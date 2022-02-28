import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineComponent;
class ATimeDimensionAxeCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CartMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AxeMeshRoot;

	UPROPERTY(DefaultComponent, Attach = AxeMeshRoot)
	UStaticMeshComponent AxeMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent HandleInteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent AxeInteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlayerAttachComp;

	UPROPERTY(DefaultComponent, Attach = PlayerAttachComp)
	USkeletalMeshComponent EditorSkelMesh;
	default EditorSkelMesh.bHiddenInGame = true;
	default EditorSkelMesh.bIsEditorOnly = true;
	default EditorSkelMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	UHazeCapability AxeCartCapability;

	UPROPERTY()
	AActor SplineActor;

	UPROPERTY()
	FHazeTimeLike MoveAxeTimeline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HandleInteractionComp.OnActivated.AddUFunction(this, n"HandleInteractionCompActivate");
		AxeInteractionComp.OnActivated.AddUFunction(this, n"AxeInteractionCompActivate");
		MoveAxeTimeline.BindUpdate(this, n"MoveAxeTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION()
	void HandleInteractionCompActivate(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		
	}

	UFUNCTION()
	void AxeInteractionCompActivate(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		MoveAxeTimeline.PlayFromStart();
	}

	UFUNCTION()
	void MoveAxeTimelineUpdate(float CurrentValue)
	{
		AxeMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(90.f, 0.f, 0.f), CurrentValue));
	}

	UFUNCTION()
	void AttachToCart()
	{

	}
	
	UFUNCTION()
	void DetachFromCart(AHazePlayerCharacter Player, UInteractionComponent Comp)
	{

	}
}