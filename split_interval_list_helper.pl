use File::Copy;

my $retval = system('gatk', 'IntervalListTools', @ARGV);
exit $retval if $retval != 0;

my $i = 1;
for(glob('*/scattered.interval_list')) {
    #create unique names and relocate all the scattered intervals to a single directory
    File::Copy::move($_, qq{$i.interval_list});
    $i++
}
