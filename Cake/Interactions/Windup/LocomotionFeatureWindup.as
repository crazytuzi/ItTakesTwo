
class ULocomotionFeatureWindup : UHazeLocomotionFeatureBase
{

    default Tag = n"Windup";
    
	UPROPERTY(BlueprintReadOnly, Category = "WindupKey")
	FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "WindupKey")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "WindupKey|Push")
	FHazePlayBlendSpaceData StrugglePush;

	UPROPERTY(BlueprintReadOnly, Category = "WindupKey|Push")
	FHazePlayBlendSpaceData Push;

	UPROPERTY(BlueprintReadOnly, Category = "WindupKey|Pull")
	FHazePlayBlendSpaceData StrugglePull;

	UPROPERTY(BlueprintReadOnly, Category = "WindupKey|Pull")
	FHazePlayBlendSpaceData Pull;

	UPROPERTY(BlueprintReadOnly, Category = "WindupKey")
	FHazePlaySequenceData Finished;


};