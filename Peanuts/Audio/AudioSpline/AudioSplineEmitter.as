USTRUCT()
struct FAudioSplineEmitter
{
	UPROPERTY()
	UAkAudioEvent Event = nullptr;	

	UPROPERTY()
	bool bPlayOnStart = false;

	UPROPERTY()
	FName Tag = n"";
}
