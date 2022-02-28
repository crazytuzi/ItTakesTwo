import Vino.Movement.Swinging.SwingPoint;

event void FOnRopeMoving(float Value);
event void FOnRopeAttach(bool bAttached);

class AHopscotchDungeonSpinnerRope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent RopeMesh;

	UPROPERTY()
	ASwingPoint ConnectedSwingPoint;

	UPROPERTY()
	FOnRopeMoving OnRopeMoving;

	UPROPERTY()
	FOnRopeAttach OnRopeAttach;

	float MeshRootStartLocZ;
	float MeshStartScaleZ;

	/* --- Bounce Properies --- */
	float LowerBound = -15.f;
	float UpperBound = 300.f;
	float LowerBounciness = .1f;
	float UpperBounciness = .25f;
	float Friction = .25f;
	float AccelerationForce = 500.f;
	float ImpactImpulseForce = 0.f;
	float SpringValue = .04f;
	int PlayersOnSwing = 0;
	TArray<AHazePlayerCharacter> PlayersOnSwingArray;
	FHazeConstrainedPhysicsValue PhysValue;
	/* -------------------------*/


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConnectedSwingPoint.OnSwingPointAttached.AddUFunction(this, n"OnSwingAttach");
		ConnectedSwingPoint.OnSwingPointDetached.AddUFunction(this, n"OnSwingDetach");

		ConnectedSwingPoint.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		PhysValue.LowerBound = LowerBound;
		PhysValue.UpperBound = UpperBound;
		PhysValue.LowerBounciness = LowerBounciness;
		PhysValue.UpperBounciness = UpperBounciness;
		PhysValue.Friction = Friction;

		MeshRootStartLocZ = MeshRoot.RelativeLocation.Z;
		MeshStartScaleZ = RopeMesh.RelativeScale3D.Z;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//RopeMesh.SetRelativeScale3D(FVector(RopeMesh.RelativeScale3D.X, RopeMesh.RelativeScale3D.Y, MeshStartScaleZ + ((MeshRootStartLocZ - MeshRoot.RelativeLocation.Z) / 100.f)));

		PrintToScreen("PhysValue.UpperBound: " + PhysValue.UpperBound);

		PhysValue.AddAcceleration(AccelerationForce * PlayersOnSwing);
		PhysValue.SpringTowards(0.f, SpringValue);
		
		PhysValue.Update(DeltaTime); 


		MeshRoot.SetRelativeLocation(FVector::UpVector * -PhysValue.Value);

		float Diff = MeshRootStartLocZ - MeshRoot.RelativeLocation.Z;
		OnRopeMoving.Broadcast(Diff);
	}

	UFUNCTION()
	void OnSwingAttach(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(ImpactImpulseForce);
		PlayersOnSwingArray.AddUnique(Player);
		UpdateNumOfPlayers();
		OnRopeAttach.Broadcast(true);

		//PrintToScreenScaled("Rope swing attach", 2.f, FLinearColor :: LucBlue, 2.f);
	}

	UFUNCTION()
	void OnSwingDetach(AHazePlayerCharacter Player)
	{
		PlayersOnSwingArray.Remove(Player);
		UpdateNumOfPlayers();
		OnRopeAttach.Broadcast(false);

		//PrintToScreenScaled("Rope swing detach", 2.f, FLinearColor :: LucBlue, 2.f);
	}

	void UpdateNumOfPlayers()
	{
		PlayersOnSwing = PlayersOnSwingArray.Num();
	}
}