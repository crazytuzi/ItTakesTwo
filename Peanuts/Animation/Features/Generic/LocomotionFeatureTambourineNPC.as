class ULocomotionFeatureTambourineNPC : UHazeLocomotionFeatureBase 
{


    ULocomotionFeatureTambourineNPC()
    {
        Tag = n"TambourineNPC";
    }

	// General movement

    
    
	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData Idle;
	
	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData PlayersClose;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData Teleport;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData WaitingToStartMiniGame;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData SmallHitReaction;
	
	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData BigHitReaction;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData EnterLoop;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData Loop;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData ExitLoop;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData JumpOn;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData GroundPound;

	UPROPERTY(Category = "Tambourine")
    FHazePlaySequenceData ShakeFist;

	};