import Peanuts.Outlines.Outlines;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AClockworkKey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent KeyMesh;
	default KeyMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION()
	void AttachKeyToPlayer(AHazePlayerCharacter Player)
	{
		FName SocketName;
		SocketName = Game::GetCody() == Player ? n"CodySpinner_Socket" : n"MaySpinner_Socket";
		AttachToActor(Player, SocketName, EAttachmentRule::SnapToTarget);
		Root.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
		CreateMeshOutlineBasedOnPlayer(KeyMesh, Player);
	}

	void RemoveOutline()
	{
		RemoveMeshOutlineFromMesh(KeyMesh);
	}
}