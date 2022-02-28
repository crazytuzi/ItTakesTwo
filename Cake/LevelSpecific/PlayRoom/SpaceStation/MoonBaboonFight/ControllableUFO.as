import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableLaser;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFOLaserGun;

UCLASS(Abstract)
class AControllableUFO : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase UfoMesh;

	UPROPERTY(DefaultComponent, Attach = UfoMesh)
	UHazeCameraComponent UfoCam;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.ControlSideDefaultCollisionSolver = n"VehicleCollisionSolver";
	default MoveComp.RemoteSideDefaultCollisionSolver = n"VehicleRemoteCollisionSolver";

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bDisabledAtStart = true;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent PlayerInputSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent LerpedPlayerInputSyncComp;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartInsideUfoLoopingEvent;

	float BobDistance = 60.f;
	float SwayRot = 5.f;

	FVector PlayerMovementInput;
	FVector LerpedMovementInput;
	float PlayerRotationInput;
	float MovementSpeed = 10.f;
	float MovementRotationSpeed = 100.f;

	UPROPERTY()
	AActor MoonMid;

	UPROPERTY()
	AControllableUfoLaserGun LaserGun;

	FHazeFrameMovement MoveData;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ControlCapability;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetMay());

		MoveComp.Setup(CollisionComp);

		SetCapabilityAttributeObject(n"ControllableUFO", this);
		AddCapability(n"UfoMovementCapability");
		AddCapability(n"UfoAlignToSurfaceCapability");

		Capability::AddPlayerCapabilityRequest(ControlCapability.Get(), EHazeSelectPlayer::May);

		LaserGun.AttachToComponent(UfoMesh, n"Base");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(ControlCapability.Get(), EHazeSelectPlayer::May);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// MoonMid.AddActorLocalRotation(FRotator(-PlayerMovementInput.Y * MovementSpeed * DeltaTime, PlayerRotationInput * MovementRotationSpeed * DeltaTime, PlayerMovementInput.X * MovementSpeed * DeltaTime));
		//MoveData = MoveComp.MakeFrameMovement(n"UFO");
		//MoveData.ApplyVelocity(PlayerMovementInput * 500.f);
		//MoveComp.Move(MoveData);		
	}

	void UpdatePlayerMovementInput(FVector Input, float RotRate)
	{
		PlayerMovementInput = Input;
		PlayerRotationInput = RotRate;
	}

	UFUNCTION()
	void ActivateUFO()
	{
		bActive = true;
	}
}