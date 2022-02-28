import Vino.Audio.Footsteps.AnimNotify_Footstep;
import Cake.LevelSpecific.Music.NightClub.NightClubElevatorFootsteps;


class UNightClubElevatorFootstepsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ElevatorFootsteps");

	default CapabilityDebugCategory = n"ElevatorFootsteps";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ANightClubElevatorFootsteps NightClubElevatorFootsteps;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
        
        // return EHazeNetworkActivation::DontActivate;
		// return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// return EHazeNetworkDeactivation::DeactivateLocal;
	
		return EHazeNetworkDeactivation::DontDeactivate;
			
		// return EHazeNetworkDeactivation::DeactivateFromControl;

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"FootstepHappened"));
		Player.BlockCapabilities(n"Cymbal", this);
		Player.BlockCapabilities(n"PowerfulSong", this);
		Player.BlockCapabilities(n"SongOfLife", this);
	}
	
	UFUNCTION()
	void FootstepHappened(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		// TODO@MW: Change this to a manually set parameter per notifier.
		bool foot = FMath::RandBool();
		FVector StepLocation 	= foot ? MeshComp.GetSocketLocation(n"LeftFoot") : MeshComp.GetSocketLocation(n"RightFoot");
		FRotator StepRotation 	= foot ? MeshComp.GetSocketRotation(n"LeftFoot") : MeshComp.GetSocketRotation(n"RightFoot");
		NightClubElevatorFootsteps.SpawnFootstep(MeshComp.GetWorldLocation(), StepLocation, StepRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnbindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"FootstepHappened"));
		Player.UnblockCapabilities(n"Cymbal", this);
		Player.UnblockCapabilities(n"PowerfulSong", this);
		Player.UnblockCapabilities(n"SongOfLife", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject NightClubElevatorFootstepsTemp;
		if (ConsumeAttribute(n"NightClubElevatorFootsteps", NightClubElevatorFootstepsTemp))
		{
			NightClubElevatorFootsteps = Cast<ANightClubElevatorFootsteps>(NightClubElevatorFootstepsTemp);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}